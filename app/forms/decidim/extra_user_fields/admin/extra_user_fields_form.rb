# frozen_string_literal: true

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
		attribute :name, String
		attribute :surname, String
        # EndBlock

        def map_model(model)
          self.enabled = model.extra_user_fields["enabled"]
          self.country = model.extra_user_fields.dig("country", "enabled")
          self.postal_code = model.extra_user_fields.dig("postal_code", "enabled")
          self.date_of_birth = model.extra_user_fields.dig("date_of_birth", "enabled")
          self.gender = model.extra_user_fields.dig("gender", "enabled")
          # Block ExtraUserFields MapModel
		  self.name = model.extra_user_fields.dig("name", "enabled")
		  self.surname = model.extra_user_fields.dig("surname", "enabled")
          # EndBlock
        end
      end
    end
  end
end