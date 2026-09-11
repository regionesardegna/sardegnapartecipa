# config/initializers/saml_debug.rb

# 1. Direziona tutti i log di ruby-saml (usato da omniauth-saml) verso il log di Rails
OneLogin::RubySaml::Logging.logger = Rails.logger

# 2. Imposta il livello a DEBUG per vedere il passaggio dei dati
OneLogin::RubySaml::Logging.logger.level = Logger::DEBUG

=begin
module RubySamlErrorLogger
    def is_valid?(collect_errors: true)
      valid = super(collect_errors: true)
      unless valid
        Rails.logger.error "================ [RUBY-SAML DETAILED ERRORS] ================"
        errors.each { |err| Rails.logger.error " -> #{err}" }
        Rails.logger.error "=============================================================="
      end
      valid
    end
end

OneLogin::RubySaml::Response.prepend(RubySamlErrorLogger)
=end