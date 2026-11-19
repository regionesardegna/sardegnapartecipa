# frozen_string_literal: true

require "rails_helper"
require "selenium-webdriver"
require "tmpdir"

RSpec.describe "Stadia Maps frontend autocomplete", type: :system do
  include Warden::Test::Helpers

  let(:organization) { create(:organization, host: "127.0.0.1", default_locale: :it, available_locales: [:it]) }
  let(:user) { create(:user, :admin, :confirmed, organization: organization, locale: :it) }
  let(:participatory_process) { create(:participatory_process, organization: organization) }
  let(:component) { create(:meeting_component, participatory_space: participatory_process) }
  let(:chrome_profile_dir) { Dir.mktmpdir("chrome-profile") }

  before do
    WebMock.disable_net_connect!(allow_localhost: true) if defined?(WebMock)
    allow_any_instance_of(ActionDispatch::Request).to receive(:ssl?).and_return(true)

    profile_dir = chrome_profile_dir
    Capybara.register_driver :stadia_headless_chrome do |app|
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument("--headless=new")
      options.add_argument("--no-sandbox")
      options.add_argument("--disable-dev-shm-usage")
      options.add_argument("--disable-gpu")
      options.add_argument("--window-size=1400,1400")
      options.add_argument("--disable-features=HttpsFirstBalancedModeAutoEnable,HttpsUpgrades")
      options.add_argument("--user-data-dir=#{profile_dir}")

      driver = Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
      driver.singleton_class.prepend(Module.new do
        def reset!
          browser.navigate.to("about:blank")
        end
      end)
      driver
    end

    driven_by :stadia_headless_chrome

    allow(Decidim).to receive(:maps).and_return(
      provider: :stadia,
      api_key: "test-stadia-api-key",
      dynamic: { style: "alidade_smooth" },
      static: { style: "alidade_smooth" },
      geocoding: {},
      autocomplete: {}
    )

    Capybara.always_include_port = true
    Capybara.app_host = "http://#{organization.host}"
    Warden.test_mode!
    login_as user, scope: :user
  end

  after do
    Warden.test_reset!
    Capybara.app_host = nil
    FileUtils.rm_rf(chrome_profile_dir)
  end

  it "mostra i suggerimenti di Stadia e compila le coordinate alla selezione" do
    visit Decidim::EngineRouter.admin_proxy(component).new_meeting_path

    find("#meeting_type_of_meeting option[value='in_person']").select_option

    page.execute_script(<<~JS)
      const originalFetch = window.fetch;
      window.fetch = function(url, options) {
        if (typeof url === "string" && url.includes("api.stadiamaps.com/geocoding/v1/autocomplete")) {
          return Promise.resolve(new Response(JSON.stringify({
            features: [{
              geometry: { type: "Point", coordinates: [9.1217, 39.2238] },
              properties: { label: "Via Roma, Cagliari, Italia" }
            }]
          }), { status: 200, headers: { "Content-Type": "application/json" } }));
        }
        return originalFetch.apply(this, arguments);
      };
    JS

    address_input = find("[data-decidim-geocoding]")
    address_input.click
    address_input.send_keys("Via Roma")

    expect(page).to have_content("Via Roma, Cagliari, Italia")
    find("li[role='option']", text: "Via Roma, Cagliari, Italia").click

    expect(find("input[name$='[latitude]']", visible: :all).value).to eq("39.2238")
    expect(find("input[name$='[longitude]']", visible: :all).value).to eq("9.1217")
  end
end