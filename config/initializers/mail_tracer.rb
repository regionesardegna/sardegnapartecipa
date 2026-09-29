# config/initializers/mail_tracer.rb
ActiveSupport::Notifications.subscribe("deliver.action_mailer") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  mailer = event.payload[:mailer]
  action = event.payload[:action]
  to = event.payload[:key] || event.payload[:to]

  Rails.logger.info "🔍 [MAIL TRACE] Inviata da: #{mailer}##{action} a #{to}"
  
  # Stampa le prime 5 righe dello stack trace relative all'app o alle gemme di Decidim
  relevant_caller = caller.select { |line| line.include?("decidim") || line.include?("app/") }.first(5)
  Rails.logger.info "📍 [MAIL CALLER]:\n#{relevant_caller.join("\n")}"
end