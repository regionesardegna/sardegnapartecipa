# frozen_string_literal: true

# Copyright (C) 2025 Sardegna IT
#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Helper backoffice con loghi CIE e SPID per aggiungere un badge agli utenti che hanno utilizzato
# queste autorizzazioni - modificato per sostituire l'icona corrispondente a SPID con quella dell'AM

module Decidim
  module Spid
    module Admin
      module ApplicationHelper

        def cie_icon
          content_tag :span, class: 'cie-badge' do
            image_pack_tag 'media/images/Logo_CIE_ID.svg', alt: "CIE Icon"
          end
        end

        def spid_icon
          content_tag :span, class: 'spid-badge' do
            image_pack_tag 'media/images/am-logo.svg', alt: "Access Manager Icon"
          end
        end
      end
    end
  end
end