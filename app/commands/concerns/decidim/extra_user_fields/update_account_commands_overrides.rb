# frozen_string_literal: true

# Copyright (C) 2025 Sardegna IT
#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>
#
# Modificato per aggiungere i campi nome e cognome tramite il modulo ExtraUserFields

require "active_support/concern"

module Decidim
  module ExtraUserFields
    # Changes in methods to store extra fields in user profile
    module UpdateAccountCommandsOverrides
      extend ActiveSupport::Concern

      private

      def update_personal_data
        @user.name = @form.name
        @user.nickname = @form.nickname
        @user.email = @form.email
        @user.personal_url = @form.personal_url
        @user.about = @form.about
        @user.extended_data = extended_data
      end

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
    end
  end
end