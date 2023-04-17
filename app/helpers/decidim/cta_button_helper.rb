# Copyright (C) 2023 Sardegna IT
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Modificata per forzare l'inizio della sessione dalla homepage bypassando la pagina di login

# frozen_string_literal: true

module Decidim
  # A Helper to render the Call To Action button.
  module CtaButtonHelper
    # Renders the Call To Action button. Link and text can be configured
    # per organization.
    def cta_button
      button_text = translated_attribute(current_organization.cta_button_text).presence || t("decidim.pages.home.hero.participate")

      link_to button_text, cta_button_path, class: "hero-cta button expanded large button--sc", title: t("decidim.pages.home.hero.participate_title")
    end

    # Finds the CTA button path to reuse it in other places.
    def cta_button_path
      if current_organization.cta_button_path.present?
        current_organization.cta_button_path
      elsif Decidim::ParticipatoryProcess.where(organization: current_organization).published.any?
        decidim_participatory_processes.participatory_processes_path
      elsif current_user
        decidim.account_path
      elsif current_organization.sign_up_enabled?
        decidim.new_user_registration_path
      else
        decidim.root_path
      end
    end
  end
end