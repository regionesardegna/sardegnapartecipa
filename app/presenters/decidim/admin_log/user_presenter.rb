# Copyright (C) 2024 Sardegna IT
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>
#
# Modulo che permette il logging delle azioni di registrazione, login e logout relative all'utente che si autentica tramite il form di registrazione/autenticazione interno, anche allo scopo di tracciare l'IP

# frozen_string_literal: true

module Decidim
  module AdminLog
    # This class holds the logic to present a `Decidim::User`
    # for the `AdminLog` log.
    #
    # Usage should be automatic and you should not need to call this class
    # directly, but here is an example:
    #
    #    action_log = Decidim::ActionLog.last
    #    view_helpers # => this comes from the views
    #    UserPresenter.new(action_log, view_helpers).present
    class UserPresenter < Decidim::Log::BasePresenter
      private

      def action_string
        case action
        when "grant_id_documents_offline_verification", "invite", "officialize", "remove_from_admin", "show_email", "unofficialize", "block", "unblock", "promote", "transfer", "registration", "login", "logout"
          "decidim.admin_log.user.#{action}"
        else
          super
        end
      end

      def i18n_params
        super.merge(
          role: I18n.t("models.user.fields.roles.#{user_role}", scope: "decidim.admin")
        ).merge(ip: ip)
      end

      def user_role
        Array(action_log.extra.dig("extra", "invited_user_role")).last
      end

      def user_badge
        action_log.extra.dig("extra", "officialized_user_badge") || Hash.new("")
      end

      def previous_user_badge
        action_log.extra.dig("extra", "officialized_user_badge_previous") || Hash.new("")
      end

      def previous_justification
        action_log.extra.dig("extra", "previous_justification") || ""
      end

      def current_justification
        action_log.extra.dig("extra", "current_justification") || Hash.new("")
      end

      def ip
        action_log.extra.dig("user", "ip") || ""
      end

      # Overwrite the changeset for officia<lization and block actions.
      def changeset
        original = { badge: [previous_user_badge, user_badge] }
        fields = { badge: :i18n }
        if action.to_s == "block"
          original = { justification: [previous_justification, current_justification] }
          fields = { justification: :string }
        end
        Decidim::Log::DiffChangesetCalculator.new(original, fields, i18n_labels_scope).changeset
      end

      def diff_actions
        %w(officialize unofficialize block)
      end

    end
  end
end

