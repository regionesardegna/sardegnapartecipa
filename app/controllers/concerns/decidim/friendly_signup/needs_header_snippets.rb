# Copyright (C) 2024 Sardegna IT
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Modificato per aggiungere i campi nome e cognome tramite il modulo ExtraUserFields

# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module FriendlySignup
    module NeedsHeaderSnippets
      extend ActiveSupport::Concern

      included do
        helper_method :snippets, :friendly_override_activated?
      end

      def snippets
        @snippets ||= Decidim::Snippets.new

        unless @snippets.any?(:friendly_signup_snippets)
          @snippets.add(:friendly_signup_snippets, ActionController::Base.helpers.javascript_pack_tag("decidim_friendly_signup"))
          @snippets.add(:friendly_signup_snippets, ActionController::Base.helpers.stylesheet_pack_tag("decidim_friendly_signup"))
          @snippets.add(:head, @snippets.for(:friendly_signup_snippets))
        end

        @snippets
      end

      def friendly_override_activated?(feat)
        Decidim::FriendlySignup.send(feat.to_s).present?
      end
    end
  end
end