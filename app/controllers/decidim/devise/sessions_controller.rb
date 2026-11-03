# frozen_string_literal: true

# Copyright (C) 2026 Sardegna IT
#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>
#
# Modificato permettere il logging delle azioni di login e logout relative all'utente che si autentica tramite il form di registrazione/autenticazione interno, anche allo scopo di tracciare l'IP

module Decidim
  module Devise
    # Custom Devise SessionsController to avoid namespace problems.
    class SessionsController < ::Devise::SessionsController
      include Decidim::DeviseControllers
      include Decidim::DeviseAuthenticationMethods

      before_action :check_sign_in_enabled, only: :create

      def create
        super do |user|
		  Decidim::ActionLogger.log(:login, user, user, 1)
		  if user.admin?
            # Check that the admin password passes the validation and clear the
            # `password_updated_at` field when the password is weak to force a
            # password update on the user.
            #
            # Handles a case when the user registers through the registration
            # form and they are promoted to an admin after that. In this case,
            # the newly promoted admin user would otherwise have to change their
            # password straight away even if they originally registered with a
            # strong password.
            validator = PasswordValidator.new({ attributes: :password })
            user.update!(password_updated_at: nil) unless validator.validate_each(user, :password, sign_in_params[:password])
          end
        end
      end

      def destroy
        current_user.invalidate_all_sessions!
		Decidim::ActionLogger.log(:logout, current_user,  current_user, 1)
        if params[:translation_suffix].present?
          super { set_flash_message! :notice, params[:translation_suffix], { scope: "decidim.devise.sessions" } }
        else
          super
        end
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