# frozen_string_literal: true

require "rails_helper"

describe "Bottone nuova conversazione", type: :request do
  let(:organization) { create(:organization, default_locale: :it, available_locales: [:it]) }
  let(:user) { create(:user, :confirmed, organization: organization) }

  before do
    host! organization.host
    login_as user, scope: :user
    I18n.locale = :it
  end

  context "quando can_user_send_private_message è true" do
    before do
      allow_any_instance_of(Decidim::Organization).to receive(:can_user_send_private_message?).and_return(true)
      get decidim.conversations_path
    end

    it "mostra il bottone" do
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="start-conversation-dialog-button"')
    end
  end

  context "quando can_user_send_private_message é false" do
    before do
      allow_any_instance_of(Decidim::Organization).to receive(:can_user_send_private_message?).and_return(false)
      get decidim.conversations_path
    end

    it "non mostra il bottone" do
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('id="start-conversation-dialog-button"')
    end
  end
end
