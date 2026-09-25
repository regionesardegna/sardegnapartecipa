class SamlResponseLogger
  def initialize(app)
    @app = app
  end

  def call(env)
    req = Rack::Request.new(env)

    # Intercetta le chiamate POST a /spid/samlsso o qualunque callback SAML
    if req.post? && req.params['SAMLResponse'].present?
      begin
        raw_xml = Base64.decode64(req.params['SAMLResponse'])
        Rails.logger.info("=" * 60)
        Rails.logger.info("[INCOMING IDP SAML RESPONSE XML]")
        Rails.logger.info(raw_xml)
        Rails.logger.info("=" * 60)
      rescue => e
        Rails.logger.error("[SAML LOGGER ERROR] Impossibile decodificare: #{e.message}")
      end
    end

    @app.call(env)
  end
end

# Inserisci in cima alla chain di Rails
Rails.application.config.middleware.unshift SamlResponseLogger unless Rails.env.test?

