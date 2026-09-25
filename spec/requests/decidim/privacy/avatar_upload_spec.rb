# spec/requests/decidim/privacy/avatar_upload_spec.rb
# frozen_string_literal: true

require "rails_helper"

describe "Avatar Upload", type: :request do
  let(:organization) { create(:organization, default_locale: :it, available_locales: [:it]) }
  let(:user) { create(:user, :confirmed, organization: organization) }

  before do
    # Imposta l'host corretto per l'organizzazione
    host! organization.host
    # Login tramite Warden (Devise integration)
    login_as user, scope: :user
    I18n.locale = :it
  end

  context "quando l'upload dell'avatar è permesso" do
    before do
      allow_any_instance_of(Decidim::Organization).to receive(:can_upload_avatar?).and_return(true)
      get decidim.account_path
    end

    it "mostra il campo per l'upload" do
      expect(response).to have_http_status(:ok)
      # Verifica la presenza dell'input nel corpo della risposta HTML
      expect(response.body).to include("type=\"file\"")
      expect(response.body).to include("avatar")
    end
  end

  context "quando l'avatar non è permesso" do
    before do
      allow_any_instance_of(Decidim::Organization).to receive(:can_upload_avatar?).and_return(false)
      get decidim.account_path
    end

    it "non mostra il campo per l'upload" do
      expect(response).to have_http_status(:ok)
      # Verifica che l'input NON sia presente
      expect(response.body).not_to include("name=\"user[avatar]\"")
    end
  end
end
