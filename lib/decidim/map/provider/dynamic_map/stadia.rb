# frozen_string_literal: true

# Copyright (C) 2026 Sardegna IT
#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>
#
# Integrazione per Stadia Maps - Mappe dinamiche

module Decidim
  module Map
    module Provider
      module DynamicMap
        class Stadia < Decidim::Map::Provider::DynamicMap::Osm
          def builder_options
            super.deep_merge(
              tile_layer: {
                url: tile_layer_url,
                options: tile_layer_options
              }
            )
          end

          private

          def tile_layer_url
            return configuration.dig(:tile_layer, :url) if configuration.dig(:tile_layer, :url).present?

            api_key = configuration[:api_key]
            style = configuration.fetch(:style, "alidade_smooth")
            url = "https://tiles.stadiamaps.com/tiles/#{style}/{z}/{x}/{y}{r}.png"
            api_key.present? ? "#{url}?api_key=#{api_key}" : url
          end

          def tile_layer_options
            configuration.dig(:tile_layer, :options) || {
              maxZoom: 20,
              attribution: '&copy; <a href="https://www.stadiamaps.com/" target="_blank">Stadia Maps</a> ' \
                           '&copy; <a href="https://openmaptiles.org/" target="_blank">OpenMapTiles</a> ' \
                           '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a> contributors'
            }
          end
        end
      end
    end
  end
end