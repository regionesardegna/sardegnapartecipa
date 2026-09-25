# frozen_string_literal: true

require "rails_helper"

describe "Follow Button", type: :request do
  let(:organization) { create(:organization, default_locale: :it, available_locales: [:it]) }
  let(:user) { create(:user, :confirmed, organization: organization) }
  let(:profile_user) { create(:user, :confirmed, organization: organization) }

  before do
    host! organization.host
    login_as user, scope: :user
    I18n.locale = :it
  end

  context "quando la possibilità di seguire è abilitata" do
    before do
      allow_any_instance_of(Decidim::Organization).to receive(:can_user_follow?).and_return(true)
      get decidim.profile_following_path(nickname: profile_user.nickname)
    end

    it "mostra il bottone Segui nella barra laterale" do
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="follow_user_')
    end
  end

  context "quando la possibilità di seguire è disabilitata" do
    before do
      allow_any_instance_of(Decidim::Organization).to receive(:can_user_follow?).and_return(false)
      get decidim.profile_following_path(nickname: profile_user.nickname)
    end

    it "non mostra il bottone Segui nella barra laterale" do
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('id="follow_user_')
    end
  end
end
