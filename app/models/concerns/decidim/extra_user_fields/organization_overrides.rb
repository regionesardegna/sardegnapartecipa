# frozen_string_literal: true

# Copyright (C) 2025 Sardegna IT
#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Incluso senza modifiche per rendere visibile extra_user_fields_enabled? 

require "active_support/concern"

module Decidim
  module ExtraUserFields
    # Changes in methods to store extra fields in user profile
    module OrganizationOverrides
      extend ActiveSupport::Concern

      # If true display registration field in signup form
      def extra_user_fields_enabled?
        extra_user_fields["enabled"].presence && at_least_one_extra_field?
      end

      def at_least_one_extra_field?
        extra_user_fields.reject { |key| %w(enabled underage_limit).include?(key) }
                         .map { |_, value| value["enabled"] }.any?
      end

      # Check if the given value is enabled in extra_user_fields
      def activated_extra_field?(sym)
        extra_user_fields.dig(sym.to_s, "enabled") == true
      end
      def age_limit?
        extra_user_fields["underage_limit"].to_i
      end

      def extra_user_field_configuration(sym)
        return {} unless activated_extra_field?(sym)

        extra_user_fields[sym.to_s].except("enabled")
      end

    end
  end
end