# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OmniAuth Registration Email Locking", type: :system do
  let!(:organization) do
    Decidim::Organization.find_by(host: "127.0.0.1") || 
    create(:organization, name: "SardegnaPartecipaTEST", host: "127.0.0.1", reference_prefix: "ORG")
  end

  before do
    Capybara.app_host = "http://#{organization.host}"
  end

  context "quando l'utente si autentica con SPID" do
    let(:spid_omniauth_data) do
      {
        "provider" => "spid",
        "uid" => "MRORSS60R13B355C",
        "info" => {
          "email" => "utente.spid@example.com",
          "name" => "Mario",
          "nickname" => "mario_spid"
        },
        "extra" => {
          "raw_info" => {
            "issuer" => "https://posteid.poste.it"
          }
        }
      }
    end

    it "mostra il campo email valorizzato e in sola lettura (readonly)" do
      # Simuliamo la sessione popolata da Decidim al termine del callback OmniAuth
      page.set_rack_session("decidim.omniauth_data" => spid_omniauth_data)

      visit decidim.new_user_registration_path

      email_field = find_field("user_email")

      # Verifichiamo il valore e la presenza dell'attributo readonly
      expect(email_field.value).to eq("utente.spid@example.com")
      expect(email_field[:readonly]).to eq("true")
    end

    it "mantiene il campo readonly anche se la validazione del form fallisce" do
      page.set_rack_session("decidim.omniauth_data" => spid_omniauth_data)

      visit decidim.new_user_registration_path

      # Sottomettiamo il form senza compilare i campi obbligatori (es. nickname o ToS)
      within ".new_user" do
        click_button "Completa la registrazione"
      end

      # Il form viene ricaricato con errori di validazione
      email_field = find_field("user_email")
      expect(email_field.value).to eq("utente.spid@example.com")
      expect(email_field[:readonly]).to eq("true")
    end
  end

  context "quando l'utente si autentica con CIE" do
    let(:cie_omniauth_data) do
      {
        "provider" => "spid", # Stesso provider di OmniAuth
        "uid" => "MRORSS60R13B355C",
        "info" => {
          "email" => "utente.cie@example.com",
          "name" => "Giuseppe",
          "nickname" => "giuseppe_cie"
        },
        "extra" => {
          "raw_info" => {
            # Issuer specifico della CIE
            "issuer" => "https://idserver.servizicid.interno.gov.it/idp/profile/SAML2/POST/SSO"
          }
        }
      }
    end

    it "mostra il campo email liberamente modificabile" do
      page.set_rack_session("decidim.omniauth_data" => cie_omniauth_data)

      visit decidim.new_user_registration_path

      email_field = find_field("user_email")

      # Il campo contiene l'email ma NON ha l'attributo readonly
      expect(email_field.value).to eq("utente.cie@example.com")
      expect(email_field[:readonly]).to be_nil

      # Verifichiamo che si possa effettivamente digitare nel campo
      fill_in "user_email", with: "nuova.email.cie@example.com"
      expect(email_field.value).to eq("nuova.email.cie@example.com")
    end

    it "mantiene il campo modificabile anche in caso di errore di validazione" do
      page.set_rack_session("decidim.omniauth_data" => cie_omniauth_data)

      visit decidim.new_user_registration_path

      # L'utente modifica l'email
      fill_in "user_email", with: "nuova.email.cie@example.com"

      # Invia il form (che fallisce per mancanza di altri dati obbligatori)
      within ".new_user" do
        click_button "Completa la registrazione"
      end

      email_field = find_field("user_email")

      # L'email inserita dall'utente viene preservata e il campo rimane modificabile
      expect(email_field.value).to eq("nuova.email.cie@example.com")
      expect(email_field[:readonly]).to be_nil
    end
  end
end