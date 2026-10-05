# frozen_string_literal: true

require "rails_helper"
require "decidim/dev/test/rspec_support/capybara"

describe "Registration" do
  include Decidim::CapybaraTestHelpers
  let(:organization) { create(:organization, default_locale: :it, available_locales: [:it]) }

  before do
    switch_to_host(organization.host)
    
    # Imposta la lingua per evitare errori di traduzione
    I18n.locale = :it
    
    visit decidim.new_user_registration_path
  end

  context "quando ci si registra" do
    it "non apre la modale newsletter al submit" do
      fill_in :registration_user_name, with: "Nikola Tesla"
      fill_in :registration_user_email, with: "nikola.tesla@example.org"
      fill_in :registration_user_password, with: "sekritpass123"
      
      within "form.new_user" do
        find("*[type=submit]").click
      end
      
      # Verifica che la modale non sia presente o visibile
      expect(page).not_to have_css("#sign-up-newsletter-modal", visible: :visible)
    end
  end
end
