# Copyright (C) 2023 Sardegna IT
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Modificata per forzare l'inizio della sessione dalla homepage bypassando la pagina di login

# frozen_string_literal: true

module Decidim
  module Devise
    # This controller customizes the behaviour of Devise's
    # RegistrationsController so we can specify a custom layout.
    class RegistrationsController < ::Devise::RegistrationsController
      include FormFactory
      include Decidim::DeviseControllers
      include NeedsTosAccepted

      helper Decidim::PasswordsHelper

      before_action :check_sign_up_enabled
      before_action :configure_permitted_parameters

      invisible_captcha

      def new
        @form = form(RegistrationForm).from_params(
          user: { sign_up_as: "user" }
        )
      end

      def create
        @form = form(RegistrationForm).from_params(params[:user].merge(current_locale:))

        CreateRegistration.call(@form) do
          on(:ok) do |user|
            if user.active_for_authentication?
              set_flash_message! :notice, :signed_up
              sign_up(:user, user)
              respond_with user, location: after_sign_up_path_for(user)
            else
              set_flash_message! :notice, :"signed_up_but_#{user.inactive_message}"
              expire_data_after_sign_in!
              respond_with user, location: after_inactive_sign_up_path_for(user)
            end
          end

          on(:invalid) do
            flash.now[:alert] = @form.errors.full_messages.join(", ") if @form.errors.full_messages.any?
            render :new
          end
        end
      end

      protected

      def check_sign_up_enabled
        redirect_to root_path unless current_organization.sign_up_enabled?
      end

      def configure_permitted_parameters
        devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :tos_agreement])
      end

      # Called before resource.save
      def build_resource(hash = nil)
        super(hash)
        resource.organization = current_organization
      end

      def devise_mapping
        ::Devise.mappings[:user]
      end
    end
  end
end