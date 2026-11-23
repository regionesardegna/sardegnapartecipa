# frozen_string_literal: true

require "rails_helper"
require "webmock/rspec"

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.describe "Stadia Maps provider" do
  let(:organization) { create(:organization) }
  let(:api_key) { "test-stadia-api-key" }
  let(:base_config) { { api_key: api_key } }

  describe Decidim::Map::Provider::DynamicMap::Stadia do
    subject(:provider) { described_class.new(organization: organization, config: config) }

    let(:config) { base_config }

    it "configura il tile_layer di default con alidade_smooth e api_key" do
      tile_layer = provider.builder_options[:tile_layer]

      expect(tile_layer[:url]).to eq(
        "https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}{r}.png?api_key=#{api_key}"
      )
      expect(tile_layer[:options][:maxZoom]).to eq(20)
      expect(tile_layer[:options][:attribution]).to include("Stadia Maps")
    end

    context "con stile personalizzato e senza api_key (Domain Authentication)" do
      let(:config) { { style: "osm_bright" } }

      it "genera l'URL senza query string api_key" do
        expect(provider.builder_options[:tile_layer][:url]).to eq(
          "https://tiles.stadiamaps.com/tiles/osm_bright/{z}/{x}/{y}{r}.png"
        )
      end
    end
  end

  describe Decidim::Map::Provider::StaticMap::Stadia do
    subject(:provider) { described_class.new(organization: organization, config: base_config) }

    let(:latitude) { 41.8933 }
    let(:longitude) { 12.4829 }

    it "costruisce l'URL statico con parametri center, size, m e api_key" do
	  url = provider.url(latitude: latitude, longitude: longitude, options: { zoom: 16, width: 300, height: 200 })
	  uri = URI.parse(url)
	  params = Rack::Utils.parse_query(uri.query)

	  expect(uri.host).to eq("tiles.stadiamaps.com")
	  expect(uri.path).to eq("/static/alidade_smooth.png")
	  expect(params).to eq(
		"center" => "41.8933,12.4829",
		"zoom" => "16",
		"size" => "300x200",
		"m" => "41.8933,12.4829",
		"api_key" => api_key
	  )
	end

    it "scarica i byte dell'immagine PNG tramite #image_data" do
	  fake_png = "\x89PNG\r\n\x1a\nfake-binary-content".b

	  stub_request(:get, %r{\Ahttps://tiles\.stadiamaps\.com/static/alidade_smooth\.png})
		.with(query: hash_including("api_key" => "test-stadia-api-key", "center" => "41.8933,12.4829", "m" => "41.8933,12.4829"))
		.to_return(status: 200, body: fake_png, headers: { "Content-Type" => "image/png" })

	  expect(provider.image_data(latitude: latitude, longitude: longitude)).to eq(fake_png)
	end
  end

  describe Decidim::Map::Provider::Geocoding::Stadia do
    subject(:provider) { described_class.new(organization: organization, config: base_config.merge(cache: nil)) }

    let!(:previous_always_raise) { Geocoder.config.always_raise }
    let(:pelias_response) do
      {
        features: [
          {
            geometry: { type: "Point", coordinates: [12.4829, 41.8933] },
            properties: {
              label: "Piazza del Campidoglio, Roma, Italia",
              name: "Piazza del Campidoglio",
              locality: "Roma",
              country: "Italia"
            }
          }
        ]
      }.to_json
    end

    before { Geocoder.configure(always_raise: :all) }
    after { Geocoder.configure(always_raise: previous_always_raise) }

    it "interroga l'endpoint Pelias di Stadia e restituisce [lat, lng]" do
      stub = stub_request(:get, "https://api.stadiamaps.com/geocoding/v1/search")
             .with(query: hash_including("text" => "Piazza del Campidoglio, Roma", "api_key" => api_key))
             .to_return(status: 200, body: pelias_response, headers: { "Content-Type" => "application/json" })

      expect(provider.coordinates("Piazza del Campidoglio, Roma")).to eq([41.8933, 12.4829])
      expect(stub).to have_been_requested
    end
  end
  
  describe Decidim::Map::Provider::Autocomplete::Stadia do
    subject(:provider) { described_class.new(organization: organization, config: base_config) }

    it "espone endpoint autocomplete e api_key nelle builder_options" do
      expect(provider.builder_options).to eq(
        url: "https://api.stadiamaps.com/geocoding/v1/autocomplete",
        api_key: api_key
      )
    end

    describe "il builder" do
      let(:template) { double }
      let(:builder) { provider.create_builder(template) }

      it "carica il pack e serializza api_key in camelCase nel campo" do
        expect(template).to receive(:append_javascript_pack_tag).with("decidim_geocoding_provider_stadia")
        expect(template).to receive(:text_field) do |_object_name, _method, options|
          expect(JSON.parse(options.fetch("data-decidim-geocoding"))).to eq(
            "url" => "https://api.stadiamaps.com/geocoding/v1/autocomplete",
            "apiKey" => api_key
          )
        end

        builder.geocoding_field(:meeting, :address)
      end

      it "serializza l'endpoint senza apiKey quando la chiave non è configurata" do
        provider_without_key = described_class.new(organization: organization, config: {})
        builder_without_key = provider_without_key.create_builder(template)

        allow(template).to receive(:append_javascript_pack_tag)
        expect(template).to receive(:text_field) do |_object_name, _method, options|
          expect(JSON.parse(options.fetch("data-decidim-geocoding"))).to eq(
            "url" => "https://api.stadiamaps.com/geocoding/v1/autocomplete"
          )
        end

        builder_without_key.geocoding_field(:meeting, :address)
      end
    end
  end

  describe "risoluzione tramite Decidim::Map" do
    before do
      allow(Decidim).to receive(:maps).and_return(
        provider: :stadia,
        api_key: api_key,
        dynamic: { style: "alidade_smooth" },
        static: { style: "alidade_smooth" },
        geocoding: {},
        autocomplete: {}
      )
    end

    it "istanzia tutte e quattro le classi :stadia" do
      expect(Decidim::Map.dynamic(organization: organization))
        .to be_a(Decidim::Map::Provider::DynamicMap::Stadia)
      expect(Decidim::Map.static(organization: organization))
        .to be_a(Decidim::Map::Provider::StaticMap::Stadia)
      expect(Decidim::Map.geocoding(organization: organization))
        .to be_a(Decidim::Map::Provider::Geocoding::Stadia)
      expect(Decidim::Map.autocomplete(organization: organization))
        .to be_a(Decidim::Map::Provider::Autocomplete::Stadia)
    end
  end
end
