# config/initializers/omniauth.rb

# 1. Logger dedicato e indipendente con rotazione giornaliera
saml_log_path = Rails.root.join("log/saml_debug.log")
SAML_LOGGER = ActiveSupport::Logger.new(saml_log_path, "daily")
SAML_LOGGER.formatter = ::Logger::Formatter.new

allowed_levels = %w[debug info warn error fatal].freeze
saml_level_name = ENV.fetch("SAML_LOG_LEVEL", "debug").to_s.downcase
SAML_LOGGER.level = if allowed_levels.include?(saml_level_name)
                      Logger.const_get(saml_level_name.upcase)
                    else
                      Logger::DEBUG
                    end

# 2. Collega OmniAuth e ruby-saml al logger dedicato (senza toccare Rails.logger)
OmniAuth.config.logger = SAML_LOGGER
OneLogin::RubySaml::Logging.logger = SAML_LOGGER if defined?(OneLogin::RubySaml::Logging)

Rails.application.config.after_initialize do
  OmniAuth.config.logger = SAML_LOGGER
  OneLogin::RubySaml::Logging.logger = SAML_LOGGER if defined?(OneLogin::RubySaml::Logging)
end

# 3. Tracciamento errori di validazione SAML / OmniAuth su log dedicato
OmniAuth.config.on_failure = proc do |env|
  exception = env["omniauth.error"]
  error_type = env["omniauth.error.type"]

  SAML_LOGGER.error("=" * 60)
  SAML_LOGGER.error("[OMNIAUTH / SAML FAILURE] Type: #{error_type.inspect} | Class: #{exception&.class}")
  SAML_LOGGER.error("Messaggio: #{exception&.message}")
  if exception.is_a?(OneLogin::RubySaml::ValidationError)
    SAML_LOGGER.error("Backtrace:\n#{exception.backtrace&.first(5)&.join("\n")}")
  end
  SAML_LOGGER.error("=" * 60)

  OmniAuth::FailureEndpoint.call(env)
end

# 4. Middleware Rack per catturare SAMLRequest (uscita) e SAMLResponse (ingresso)
class SamlTrafficLogger
  def initialize(app)
    @app = app
  end

  def call(env)
    path = env["PATH_INFO"].to_s
    req = Rack::Request.new(env)

    is_auth_path = path.include?("/users/auth") || path.include?("/spid") || path.include?("/saml")
    has_saml_param = req.params.key?("SAMLResponse") || req.params.key?("SAMLRequest")
    env["rack.input"]&.rewind

    return @app.call(env) unless is_auth_path || has_saml_param

    # A. SAMLResponse in ingresso (callback POST/GET dall'IdP)
    if (saml_response = req.params["SAMLResponse"]).present?
      SAML_LOGGER.info("[INCOMING SAMLResponse] Path: #{path} | IP: #{req.ip}")
      if SAML_LOGGER.debug?
        begin
          raw_xml = Base64.decode64(saml_response)
          SAML_LOGGER.debug("=" * 60)
          SAML_LOGGER.debug("[INCOMING IDP SAML RESPONSE XML]\n#{raw_xml}")
          SAML_LOGGER.debug("=" * 60)
        rescue StandardError => e
          SAML_LOGGER.error("[SAML LOGGER ERROR] Impossibile decodificare SAMLResponse: #{e.class} - #{e.message}")
        end
      end
    end

    status, headers, body = @app.call(env)

    # B. SAMLRequest in uscita via HTTP-Redirect (302 Location)
    if status == 302 && headers["Location"].present?
      begin
        uri = URI.parse(headers["Location"])
        query_params = Rack::Utils.parse_query(uri.query.to_s)
        if query_params["SAMLRequest"].present?
          SAML_LOGGER.info("[OUTGOING SAMLRequest HTTP-Redirect] Verso: #{uri.host} | IP: #{req.ip}")
          if SAML_LOGGER.debug?
            inflated_xml = Zlib::Inflate.new(-Zlib::MAX_WBITS).inflate(Base64.decode64(query_params["SAMLRequest"]))
            SAML_LOGGER.debug("=" * 60)
            SAML_LOGGER.debug("[OUTGOING SP AUTH REQUEST XML]\n#{inflated_xml}")
            SAML_LOGGER.debug("=" * 60)
          end
        end
      rescue StandardError => e
        SAML_LOGGER.error("[SAML LOGGER ERROR] Impossibile decodificare SAMLRequest Redirect: #{e.class} - #{e.message}")
      end
    # C. SAMLRequest in uscita via HTTP-POST (200 HTML form)
    elsif status == 200 && headers["Content-Type"].to_s.include?("text/html")
      chunks = []
      body.each { |chunk| chunks << chunk }
      body.close if body.respond_to?(:close)
      html = chunks.join
      body = chunks

      if html.include?("SAMLRequest")
        match = html.match(/name=["']SAMLRequest["'][^>]*value=["']([^"']+)["']/i) ||
                html.match(/value=["']([^"']+)["'][^>]*name=["']SAMLRequest["']/i)
        if match
          SAML_LOGGER.info("[OUTGOING SAMLRequest HTTP-POST] Path: #{path} | IP: #{req.ip}")
          if SAML_LOGGER.debug?
            raw_xml = Base64.decode64(match[1])
            SAML_LOGGER.debug("=" * 60)
            SAML_LOGGER.debug("[OUTGOING SP AUTH REQUEST XML]\n#{raw_xml}")
            SAML_LOGGER.debug("=" * 60)
          end
        end
      end
    end

    [status, headers, body]
  end
end

Rails.application.config.middleware.insert_before OmniAuth::Builder, SamlTrafficLogger unless Rails.env.test?