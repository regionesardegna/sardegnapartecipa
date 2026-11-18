# frozen_string_literal: true

# Copyright (C) 2026 Sardegna IT
#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>
#
# Integrazione per Stadia Maps - Mappe statiche

# frozen_string_literal: true

module Decidim
  module Map
    module Provider
      module StaticMap
        class Stadia < Decidim::Map::StaticMap
          def url(latitude:, longitude:, options: {})
            uri = URI.parse(base_url)
            uri.query = URI.encode_www_form(
              url_params(latitude: latitude, longitude: longitude, options: options)
            )
            uri.to_s
          end

          def url_params(latitude:, longitude:, options: {})
            width = options[:width] || 120
            height = options[:height] || 120

            params = {
              center: "#{latitude},#{longitude}",
              zoom: options[:zoom] || 15,
              size: "#{width}x#{height}",
              markers: "#{latitude},#{longitude}"
            }
            params[:api_key] = configuration[:api_key] if configuration[:api_key].present?
            params
          end

          private

          def base_url
            return configuration[:url] if configuration[:url].present?

            style = configuration.fetch(:style, "alidade_smooth")
            "https://static.stadiamaps.com/static/#{style}.png"
          end
        end
      end
    end
  end
end