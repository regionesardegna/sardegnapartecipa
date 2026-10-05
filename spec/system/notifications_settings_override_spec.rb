# frozen_string_literal: true

require "rails_helper"
require "decidim/dev/test/rspec_support/capybara"

describe "NotificationsSettings", type: :system do
  include Decidim::CapybaraTestHelpers

  let(:organization) { create(:organization, default_locale: :it, available_locales: [:it]) }
  let(:user) { create(:user, :confirmed, organization:) }

  before do
    switch_to_host(organization.host)
    I18n.locale = :it
    login_as user, scope: :user
    visit decidim.notifications_settings_path
  end

  context "quando si è sulla pagina delle impostazioni di notifica" do
    it "non espone il campo newsletter" do
      # Verifica che il checkbox della newsletter non sia presente/trovabile
      expect(page).not_to have_field("newsletter_notifications")
      # Verifica che l'etichetta non sia visibile
      expect(page).not_to have_content("Newsletter")
    end
  end
end
