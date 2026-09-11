# frozen_string_literal: true

Rails.application.config.to_prepare do
  # 1. Patch sul modello Decidim::User:
  # Aggiunge un attributo virtuale per identificare le registrazioni OmniAuth
  # e saltare le validazioni stringenti sulla password.
  Decidim::User.class_eval do
    attr_accessor :omniauth_signup

    # Sovrascrive password_required? di Devise/Decidim.
    # Se omniauth_signup è true, le validazioni di complessità della password vengono saltate.
    def password_required?
      return false if omniauth_signup
      super
    end
  end

  # 2. Patch sul comando Core di Decidim (Decidim::CreateOmniauthRegistration)
  begin
    "Decidim::CreateOmniauthRegistration".constantize.class_eval do
      private

      def create_or_find_user
        @user = Decidim::User.find_or_initialize_by(
          email: verified_email,
          organization: organization
        )

        if @user.persisted?
          @user.skip_confirmation! if !@user.confirmed? && @user.email == verified_email
        else
          # Genera una password temporanea e attiva il flag omniauth_signup
          generated_password = "A1!#{SecureRandom.hex(16)}"

          @user.email = (verified_email || form.email)
          @user.name = form.name
          @user.nickname = form.normalized_nickname
          @user.newsletter_notifications_at = nil
          @user.password = generated_password
          @user.password_confirmation = generated_password
          @user.omniauth_signup = true

          if form.avatar_url.present?
            url = URI.parse(form.avatar_url)
            filename = File.basename(url.path)
            file = url.open
            @user.avatar.attach(io: file, filename: filename)
          end

          @user.skip_confirmation! if verified_email
        end

        if form.respond_to?(:personal_name) && form.personal_name.present? && @user.respond_to?(:personal_name=)
          @user.personal_name = form.personal_name
        end

        if form.respond_to?(:surname) && form.surname.present? && @user.respond_to?(:surname=)
          @user.surname = form.surname
        end

        @user.tos_agreement = "1"
        @user.save!
      end
    end
  rescue NameError => e
    Rails.logger.warn "[OVERRIDE] Decidim::CreateOmniauthRegistration non trovato: #{e.message}"
  end

  # 3. Patch di sicurezza per la gemma ExtraUserFields (se presente nell'applicazione)
  begin
    "Decidim::ExtraUserFields::OmniauthCommandsOverrides".constantize.module_eval do
      private

      def create_or_find_user
        @user = Decidim::User.find_or_initialize_by(
          email: verified_email,
          organization: organization
        )

        if @user.persisted?
          @user.skip_confirmation! if !@user.confirmed? && @user.email == verified_email
        else
          generated_password = "A1!#{SecureRandom.hex(16)}"

          @user.email = (verified_email || form.email)
          @user.name = form.name
          @user.nickname = form.normalized_nickname
          @user.newsletter_notifications_at = nil
          @user.password = generated_password
          @user.password_confirmation = generated_password
          @user.omniauth_signup = true

          if form.avatar_url.present?
            url = URI.parse(form.avatar_url)
            filename = File.basename(url.path)
            file = url.open
            @user.avatar.attach(io: file, filename: filename)
          end

          @user.skip_confirmation! if verified_email
        end

        @user.tos_agreement = "1"
        @user.extended_data = extended_data if respond_to?(:extended_data, true)
        @user.save!
      end
    end
  rescue NameError
    # Gemma non presente
  end
end