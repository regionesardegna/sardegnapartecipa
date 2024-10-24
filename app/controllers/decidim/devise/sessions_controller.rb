# Copyright (C) 2023 Sardegna IT
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Modificata per eseguire il logging degli accessi con form interno e tracciare l'ip del client

# frozen_string_literal: true

module Decidim
  module Devise
    # Custom Devise SessionsController to avoid namespace problems.
    class SessionsController < ::Devise::SessionsController
      include Decidim::DeviseControllers
	  include Decidim::FriendlySignup::NeedsHeaderSnippets

      # rubocop: disable Rails/LexicallyScopedActionFilter
      before_action :check_sign_in_enabled, only: :create
      # rubocop: enable Rails/LexicallyScopedActionFilter

      def destroy
        current_user.invalidate_all_sessions!
        Decidim::ActionLogger.log(:logout, current_user,  current_user, 1)
        if params[:translation_suffix].present?
          super { set_flash_message! :notice, params[:translation_suffix], { scope: "decidim.devise.sessions" } }
        else
          super
        end
      end

      def after_sign_in_path_for(user)
        if user.present? && user.blocked?
          check_user_block_status(user)
        elsif first_login_and_not_authorized?(user) && !user.admin? && !pending_redirect?(user)
          Decidim::ActionLogger.log(:login, user, user, 1)
          decidim_verifications.first_login_authorizations_path
        else
          Decidim::ActionLogger.log(:login, user, user, 1)
          super
        end
      end

      # Calling the `stored_location_for` method removes the key, so in order
      # to check if there's any pending redirect after login I need to call
      # this method and use the value to set a pending redirect. This is the
      # only way to do this without checking the session directly.
      def pending_redirect?(user)
        store_location_for(user, stored_location_for(user))
      end

      def first_login_and_not_authorized?(user)
        user.is_a?(User) && user.sign_in_count == 1 && current_organization.available_authorizations.any? && user.verifiable?
	  end

      def after_sign_out_path_for(user)
        request.referer || super
      end

      private

      def check_sign_in_enabled
        redirect_to new_user_session_path unless current_organization.sign_in_enabled?
      end
    end
  end
end
