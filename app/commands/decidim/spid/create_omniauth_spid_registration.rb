# frozen_string_literal: true

# Copyright (C) 2025 Sardegna IT
#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Commentata riga corrispondente allo skip_confirmation
# integrato metodo extended_data originariamente contenuto in commands/concerns/decidim/omniauth_commands_overrides.rb 
# serve a salvare i valori dei due campi opzionali Nome e Cognome all'interno del campo extended_data del User

module Decidim
  module Spid
    class CreateOmniauthSpidRegistration < ::Decidim::CreateOmniauthRegistration

      private

      def create_or_find_user
        generated_password = SecureRandom.hex

        @user = User.find_or_initialize_by(
          email: verified_email,
          organization: organization
        )

        if persisted = @user.persisted?
          @user.skip_confirmation! if !@user.confirmed? && @user.email == verified_email
          @user.name = form.name
          @user.nickname = form.nickname
          @user.password = generated_password + "0A_a" #aggiunta stringa contenente tutte le tipologie di carattere da validare
          @user.password_confirmation = generated_password + + "0A_a" #aggiunta stringa contenente tutte le tipologie di carattere da validare
        else
          @user.email = (verified_email || form.email)
          @user.name = form.name
          @user.nickname = form.normalized_nickname
          @user.newsletter_notifications_at = nil
          @user.notifications_sending_frequency = "daily"
          @user.password = generated_password + "0A_a" #aggiunta stringa contenente tutte le tipologie di carattere da validare
          @user.password_confirmation = generated_password + "0A_a" #aggiunta stringa contenente tutte le tipologie di carattere da validare
          if form.avatar_url.present?
            url = URI.parse(form.avatar_url)
            filename = File.basename(url.path)
            file = URI.open(url)
            @user.avatar.attach(io: file, filename: filename)
          end
          @user.skip_confirmation! if verified_email
        end

        @user.tos_agreement = "1"
        @user.extended_data = extended_data
        @user.save! && persisted && !@user.must_log_with_spid? && Decidim::Spid::SpidJob.perform_later(@user)       
      end
      
       # rubocop:disable Style/TrailingCommaInArguments
      def extended_data
        @extended_data ||= (@user&.extended_data || {}).merge(
          country: @form.country,
          postal_code: @form.postal_code,
          date_of_birth: @form.date_of_birth,
          gender: @form.gender,
          # Block ExtraUserFields SaveInExtendedData
          personal_name: @form.personal_name,
          surname: @form.surname,
          # EndBlock
        )
      end
      # rubocop:enable Style/TrailingCommaInArguments

    end

  end
end

