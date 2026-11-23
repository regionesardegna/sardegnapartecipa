# frozen_string_literal: true

# Copyright (C) 2026 Sardegna IT
#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>
#
# Integrazione per Stadia Maps - Autocomplete

module Decidim
  module Map
    module Provider
      module Autocomplete
        class Stadia < Decidim::Map::Autocomplete
          class Builder < Decidim::Map::Autocomplete::Builder
            def append_assets
              template.append_javascript_pack_tag("decidim_geocoding_provider_stadia")
            end
          end

          def builder_options
            super.merge(
              url: configuration[:url] || "https://api.stadiamaps.com/geocoding/v1/autocomplete",
              api_key: configuration[:api_key]
            ).compact
          end
        end
      end
    end
  end
end