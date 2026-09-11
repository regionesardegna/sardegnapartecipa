# config/initializers/debug_omniauth_errors.rb
Rails.application.config.to_prepare do
  # 1. Debug per il Form OmniAuth (ActiveModel)
  Decidim::OmniauthRegistrationForm.class_eval do
    module OmniauthFormErrorLogger
      def valid?(*args)
        result = super
        if errors.any?
          Rails.logger.error("🛑 [FORM VALIDATION ERRORS]: #{errors.full_messages.join(', ')}")
        end
        result
      end
    end
    prepend OmniauthFormErrorLogger
  end

  # 2. Debug per il modello User (ActiveRecord)
  Decidim::User.class_eval do
    module UserErrorLogger
      def valid?(*args)
        result = super
        if errors.any?
          Rails.logger.error("🛑 [USER MODEL ERRORS]: #{errors.full_messages.join(', ')}")
          Rails.logger.error("   📍 CHIAMATO DA (escludendo i moduli interni di Rails):")

          # Escludiamo le chiamate interne di ActiveRecord/ActiveModel per arrivare al codice di Decidim
          app_stack = caller_locations(1, 50).reject do |loc|
            p = loc.path
            p.include?("debug_omniauth_errors") || 
            p.include?("active_record") || 
            p.include?("active_model") || 
            p.include?("active_support")
          end

          app_stack.first(10).each do |loc|
            Rails.logger.error("      👉 #{loc.path}:#{loc.lineno} in `#{loc.label}`")
          end
        end
        result
      end
    end
    prepend UserErrorLogger
  end
end