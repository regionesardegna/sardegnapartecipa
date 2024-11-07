# Copyright (C) 2024 Sardegna IT
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Modulo che permette di esportare i valori immessi nei campi extra custom

# frozen_string_literal: true

module Decidim
  # This class serializes a User so can be exported to CSV
  module ExtraUserFields
    class UserExportSerializer < Decidim::DataPortabilitySerializers::DataPortabilityUserSerializer
      # Public: Exports a hash with the serialized data for the user including
      # extra user fields
      def serialize
        super.merge(extra_user_fields)
      end

      def extra_user_fields
        extended_data = resource.extended_data.symbolize_keys

        extra_fields.index_with do |key|
          extended_data[key]
        end
      end

      # rubocop:disable Style/TrailingCommaInArrayLiteral
      def extra_fields
        [
          :gender,
          :country,
          :postal_code,
          :date_of_birth,
          # Block ExtraUserFields AddExtraField
		  :personal_name,
		  :surname
          # EndBlock
        ]
      end
      # rubocop:enable Style/TrailingCommaInArrayLiteral
    end
  end
end