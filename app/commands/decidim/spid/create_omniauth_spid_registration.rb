# frozen_string_literal: true

# Copyright (C) 2026 Sardegna IT
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>
#
# Modificata per la gestione password modificata e per i campi aggiuntivi

module Decidim
  module Spid
    class CreateOmniauthSpidRegistration < ::Decidim::CreateOmniauthRegistration

      private

      def create_or_find_user
        # Password temporanea conforme: contiene almeno una lettera maiuscola, un numero e un simbolo speciale ("A1!")
        # per superare i controlli stringenti di PasswordValidator / devise-security.
        Rails.logger.debug "======================================================="
		Rails.logger.debug "INIZIO CREATE OR FIND USER============================="
		Rails.logger.debug "======================================================="
		generated_password = "A1!#{SecureRandom.hex(16)}"
        

	    Rails.logger.debug "============== generated_password=#{generated_password}"
		
        @user = User.find_or_initialize_by(
          email: verified_email,
          organization: organization
        )

        if (persisted = @user.persisted?)
          @user.skip_confirmation! if !@user.confirmed? && @user.email == verified_email
          @user.name = form.name
          @user.nickname = form.nickname
          @user.password = generated_password
          @user.password_confirmation = generated_password
        else
          @user.email = (verified_email || form.email)
          @user.name = form.name
          @user.nickname = form.normalized_nickname
          @user.newsletter_notifications_at = nil
          @user.notifications_sending_frequency = "daily"
          @user.password = generated_password
          @user.password_confirmation = generated_password

          if form.avatar_url.present?
            url = URI.parse(form.avatar_url)
            filename = File.basename(url.path)
            file = URI.open(url)
            @user.avatar.attach(io: file, filename: filename)
          end

          @user.skip_confirmation! if verified_email
        end

        # Assegnazione esplicita dei campi personal_name e surname provenienti da extra_user_fields
        if form.respond_to?(:personal_name) && form.personal_name.present?
          @user.personal_name = form.personal_name if @user.respond_to?(:personal_name=)
        end

        if form.respond_to?(:surname) && form.surname.present?
          @user.surname = form.surname if @user.respond_to?(:surname=)
        end

        @user.tos_agreement = "1"
        @user.save! && persisted && !@user.must_log_with_spid? && Decidim::Spid::SpidJob.perform_later(@user)
		Rails.logger.debug "======================================================="
		Rails.logger.debug "FINE CREATE OR FIND USER==============================="
		Rails.logger.debug "======================================================="
	  
	  rescue StandardError => e
		Rails.logger.debug "💥 [ECCEZIONE IN CREATE_OR_FIND_USER]: #{e.class} - #{e.message}"
		Rails.logger.debug "📜 STACKTRACE:\n#{e.backtrace.first(15).join("\n")}"
		raise e # Rilancia l'eccezione per far scattare la transazione SQL (ROLLBACK) e il rescue nel metodo call
	  end

    end
  end
end
