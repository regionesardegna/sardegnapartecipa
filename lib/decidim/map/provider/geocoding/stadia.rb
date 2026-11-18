# frozen_string_literal: true

# Copyright (C) 2026 Sardegna IT
#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>
#
# Integrazione per Stadia Maps - Geocoding

require "geocoder/lookups/pelias"
require "geocoder/results/pelias"

module Geocoder
  module Lookup
    class Stadia < Pelias
      def name
        "Stadia"
      end

      def configuration
        @stadia_configuration ||= super.tap { |cfg| cfg[:use_https] = true }
      end

      def endpoint
        configuration[:host] || "api.stadiamaps.com/geocoding"
      end

      def host
        endpoint
      end

      def protocol
        "https"
      end

      def use_https?
        true
      end

      def required_api_key_parts
        []
      end

      def base_query_url(query)
        target_host = query.options[:host] || endpoint
        "https://#{target_host}/v1/search?"
      end

      def query_url_params(query)
        params = super
        api_key = query.options[:api_key] || configuration.api_key
        if api_key.present?
          params[:api_key] = api_key
        else
          params.delete(:api_key)
        end
        params
      end

      def result_class
        Geocoder::Result::Pelias
      end
    end
  end

  module Result
    class Stadia < Pelias
    end
  end
end

Geocoder::Lookup.street_services << :stadia unless Geocoder::Lookup.street_services.include?(:stadia)
$LOADED_FEATURES << "geocoder/lookups/stadia.rb" unless $LOADED_FEATURES.include?("geocoder/lookups/stadia.rb")

module Decidim
  module Map
    module Provider
      module Geocoding
        class Stadia < Decidim::Map::Geocoding
          def geocoder_options(options = {})
            super(options).merge(
              lookup: :stadia,
              host: "api.stadiamaps.com/geocoding",
              use_https: true,
              api_key: configuration[:api_key]
            ).merge(configuration.except(:lookup, :host, :use_https)).merge(options)
          end
        end
      end
    end
  end
end