class SardaSmtpDelivery
  def initialize(values)
    @settings = values
  end

  def deliver!(mail)
    require 'net/smtp'
    
    # Estraiamo i dati dalla mail
    from = mail.return_path || mail.sender || mail.from.first
    destinations = mail.destinations

    # Creiamo la connessione SMTP "pura" come nel test di successo
    smtp = Net::SMTP.new(@settings[:address], @settings[:port])
    
    # Configurazione TLS identica al test manuale
    context = Net::SMTP.default_ssl_context
    context.set_params(verify_mode: OpenSSL::SSL::VERIFY_NONE)
    smtp.enable_starttls(context)

    smtp.start(
      @settings[:domain],
      @settings[:user_name],
      @settings[:password],
      @settings[:authentication].to_sym
    ) do |s|
      s.send_message mail.encoded, from, destinations
    end
  end
end

ActionMailer::Base.add_delivery_method :sarda_smtp, SardaSmtpDelivery