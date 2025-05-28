# frozen_string_literal: true

# Copyright (C) 2025 Sardegna IT
#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Modificato per aggiungere i campi nome e cognome tramite il modulo ExtraUserFields

module Decidim
  module ExtraUserFields
    module Admin
      class ExtraUserFieldsForm < Decidim::Form
        include TranslatableAttributes

        attribute :enabled, Boolean
        attribute :country, Boolean
        attribute :postal_code, Boolean
        attribute :date_of_birth, Boolean
        attribute :gender, Boolean

       #translatable_attribute :phone_number_placeholder, String
        # Block ExtraUserFields Attributes
        attribute :personal_name, Boolean
        attribute :surname, Boolean
        # EndBlock

        def map_model(model)
          self.enabled = model.extra_user_fields["enabled"]
          self.country = model.extra_user_fields.dig("country", "enabled")
          self.postal_code = model.extra_user_fields.dig("postal_code", "enabled")
          self.date_of_birth = model.extra_user_fields.dig("date_of_birth", "enabled")
          self.gender = model.extra_user_fields.dig("gender", "enabled")
          # Block ExtraUserFields MapModel
          self.personal_name = model.extra_user_fields.dig("personal_name", "enabled")
          self.surname = model.extra_user_fields.dig("surname", "enabled")
          # EndBlock
        end
      end
    end
  end
end