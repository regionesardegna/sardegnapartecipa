OmniAuth.config.logger = Rails.logger
OneLogin::RubySaml::Logging.logger = Rails.logger
OneLogin::RubySaml::Logging.logger.level = Logger::DEBUG

OmniAuth.config.on_failure = Proc.new do |env|
  exception = env['omniauth.error']
  
  if exception.is_a?(OneLogin::RubySaml::ValidationError)
    Rails.logger.error "================ [SAML VALIDATION ERROR] ================"
    Rails.logger.error "Messaggio di errore esatto: #{exception.message}"
    Rails.logger.error "Backtrace: #{exception.backtrace&.first(3)&.join("\n")}"
    Rails.logger.error "========================================================="
  end

  # Reindirizza alla gestione standard dei fallimenti di Decidim/Devise
  OmniAuth::FailureEndpoint.call(env)
end