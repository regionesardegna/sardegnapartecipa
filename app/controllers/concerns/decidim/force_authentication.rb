# Copyright (C) 2023 Sardegna IT
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Modificata per forzare l'inizio della sessione dalla homepage bypassando la pagina di login

# frozen_string_literal: true

module Decidim
  # Shared behaviour for force_users_to_authenticate_before_access_organization
  module ForceAuthentication
    extend ActiveSupport::Concern

    included do
      before_action :ensure_authenticated!, unless: :allow_unauthorized_path?
    end

    private

    # For Devise helper functions, see:
    # https://github.com/plataformatec/devise#getting-started
    #
    # Breaks the request lifecycle, if user is not authenticated.
    # Otherwise returns.
    def ensure_authenticated!
      return true unless current_organization.force_users_to_authenticate_before_access_organization

      # Next stop: Check whether auth is ok
      unless user_signed_in?
        flash[:warning] = t("actions.login_before_access", scope: "decidim.core")
		redirect_to decidim.root_path if (request.original_url != request.protocol + request.host_with_port + decidim.root_path && !decidim.root_path.nil?)
      end
    end

    # Check for all paths that should be allowed even if the user is not yet
    # authorized
    def allow_unauthorized_path?
      return true if unauthorized_paths.any? { |path| /^#{path}/.match?(request.path) }

      false
    end

    def unauthorized_paths
      # /locale is for changing the locale
      %w(/locale) + Decidim::StaticPage.where(
        organization: current_organization,
        allow_public_access: true
      ).pluck(Arel.sql("CONCAT('/pages/', slug)"))
    end
  end
end