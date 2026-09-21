# frozen_string_literal: true

require "rails_helper"

RSpec.describe "decidim/devise/omniauth_registrations/new", type: :view do
  let(:organization) { build(:organization, host: "127.0.0.1", reference_prefix: "ORG") }

  before do
    view.extend Devise::Controllers::UrlHelpers
    
    # Estendiamo il modulo sia sul controller che direttamente sulla vista
    controller.class.include(Decidim::FriendlySignup::NeedsHeaderSnippets)
    view.extend(Decidim::FriendlySignup::NeedsHeaderSnippets)
    
    org = organization
    
    controller.define_singleton_method(:resource) { Decidim::User.new }
    controller.define_singleton_method(:resource_name) { :user }
    controller.define_singleton_method(:devise_mapping) { Devise.mappings[:user] }
    
    view.define_singleton_method(:resource) { Decidim::User.new }
    view.define_singleton_method(:resource_name) { :user }
    view.define_singleton_method(:devise_mapping) { Devise.mappings[:user] }
    view.define_singleton_method(:current_organization) { org }
    view.define_singleton_method(:omniauth_registrations_path) { |_resource_name = nil| "/users/omniauth_callbacks" }

    allow(Decidim::FriendlySignup).to receive(:respond_to?).and_return(true)
  end

  context "quando l'utente si autentica con SPID" do
    before do
      session["decidim.omniauth_data"] = {
        "provider" => "spid",
        "info" => { "email" => "utente.spid@example.com" },
        "extra" => { "raw_info" => { "issuer" => "https://posteid.poste.it" } }
      }

      form = Decidim::OmniauthRegistrationForm.new(email: "utente.spid@example.com")
      assign(:form, form)
    end

    it "rende il campo email valorizzato, readonly e col blur" do
      render

      expect(rendered).to include('value="utente.spid@example.com"')
      expect(rendered).to include('readonly="readonly"')
      expect(rendered).to include('this.blur();')
      # Verifichiamo la presenza del campo hidden cercando il suo attributo name
      expect(rendered).to include('name="user[raw_data]"')
    end
  end

  context "quando l'utente si autentica con CIE" do
    before do
      session["decidim.omniauth_data"] = {
        "provider" => "spid",
        "info" => { "email" => "utente.cie@example.com" },
        "extra" => { "raw_info" => { "issuer" => "https://idserver.servizicid.interno.gov.it" } }
      }

      form = Decidim::OmniauthRegistrationForm.new(email: "utente.cie@example.com")
      assign(:form, form)
    end

    it "rende il campo email liberamente modificabile" do
      render

      expect(rendered).to include('value="utente.cie@example.com"')
      expect(rendered).not_to include('readonly="readonly"')
      expect(rendered).not_to include('this.blur();')
    end
  end
  
  context "quando l'utente si autentica con SPID e la validazione fallisce (es. email già esistente)" do
    before do
      session["decidim.omniauth_data"] = {
        "provider" => "spid",
        "info" => { "email" => "esistente@example.com" },
        "extra" => { "raw_info" => { "issuer" => "https://posteid.poste.it" } }
      }

      form = Decidim::OmniauthRegistrationForm.new(email: "esistente@example.com")
      # Simuliamo l'errore di validazione del modello/database
      form.errors.add(:email, "è già presente nel sistema")
      assign(:form, form)
    end

    it "mantiene il campo readonly e col blur anche in caso di errore" do
      render

      expect(rendered).to include('value="esistente@example.com"')
      expect(rendered).to include('readonly="readonly"')
      expect(rendered).to include('this.blur();')
    end
  end

  context "quando l'utente si autentica con CIE e la validazione fallisce (es. email già esistente)" do
    before do
      session["decidim.omniauth_data"] = {
        "provider" => "spid",
        "info" => { "email" => "esistente@example.com" },
        "extra" => { "raw_info" => { "issuer" => "https://idserver.servizicid.interno.gov.it" } }
      }

      form = Decidim::OmniauthRegistrationForm.new(email: "esistente@example.com")
      # Simuliamo l'errore di validazione
      form.errors.add(:email, "è già presente nel sistema")
      assign(:form, form)
    end

    it "mantiene il campo modificabile anche in caso di errore di validazione" do
      render

      expect(rendered).to include('value="esistente@example.com"')
      expect(rendered).not_to include('readonly="readonly"')
      expect(rendered).not_to include('this.blur();')
    end
  end
  
end