# config/initializers/saml_debug.rb

# 1. Direziona tutti i log di ruby-saml (usato da omniauth-saml) verso il log di Rails
OneLogin::RubySaml::Logging.logger = Rails.logger

# 2. Imposta il livello a DEBUG per vedere il passaggio dei dati
OneLogin::RubySaml::Logging.logger.level = Logger::DEBUG