# config/initializers/saml_debug.rb

#  Direziona tutti i log di ruby-saml (usato da omniauth-saml) verso il log di Rails
OneLogin::RubySaml::Logging.logger = Rails.logger

