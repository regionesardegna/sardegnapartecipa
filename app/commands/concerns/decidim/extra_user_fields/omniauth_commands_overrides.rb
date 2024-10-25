# Copyright (C) 2024 Sardegna IT
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Modificato per aggiungere i campi nome e cognome tramite il modulo ExtraUserFields

# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module ExtraUserFields
    # Changes in methods to store extra fields in user profile
    module OmniauthCommandsOverrides
      extend ActiveSupport::Concern

      private

      def create_or_find_user
        generated_password = SecureRandom.hex

        @user = User.find_or_initialize_by(
          email: verified_email,
          organization: organization
        )

        if @user.persisted?
          # If user has left the account unconfirmed and later on decides to sign
          # in with omniauth with an already verified account, the account needs
          # to be marked confirmed.
          @user.skip_confirmation! if !@user.confirmed? && @user.email == verified_email
        else
          @user.email = (verified_email || form.email)
          @user.name = form.name
          @user.nickname = form.normalized_nickname
          @user.newsletter_notifications_at = nil
          @user.email_on_notification = true
          @user.password = generated_password
          @user.password_confirmation = generated_password
          @user.remote_avatar_url = form.avatar_url if form.avatar_url.present?
          @user.skip_confirmation! if verified_email
        end

        @user.tos_agreement = "1"
        @user.extended_data = extended_data
        @user.save!
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