# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Log amministrativo di autenticazione utente da form", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:password) { "Decidim123456!" }
  
  # Forziamo sign_in_enabled: true per superare il check_sign_in_enabled del controller
  let!(:organization) { create(:organization, host: "test.host", sign_in_enabled: true) }
  
  let!(:user) do
    create(
      :user,
      :confirmed,
      organization: organization,
      password: password,
      password_confirmation: password
    )
  end
  let(:user_ip) { "192.168.1.50" }

  before do
    host! organization.host
  end

  describe "POST /users/sign_in (Login)" do
    it "crea l'ActionLog del login salvando l'utente e l'azione" do
      expect do
        post decidim.user_session_path,
             params: {
               user: {
                 email: user.email,
                 password: password
               }
             },
             headers: { "REMOTE_ADDR" => user_ip }
      end.to change(Decidim::ActionLog, :count).by(1)

      expect(response).to have_http_status(:redirect)

      log = Decidim::ActionLog.last
      expect(log.user).to eq(user)
      expect(log.action).to eq("login")
      expect(log.extra.dig("user", "ip")).to eq(user_ip) if log.extra.present?
    end
  end

  describe "DELETE /users/sign_out (Logout)" do
    before do
      sign_in user, scope: :user
    end

    it "crea l'ActionLog del logout" do
      expect do
        delete decidim.destroy_user_session_path, headers: { "REMOTE_ADDR" => user_ip }
      end.to change(Decidim::ActionLog, :count).by(1)

      expect(response).to have_http_status(:redirect)

      log = Decidim::ActionLog.last
      expect(log.user).to eq(user)
      expect(log.action).to eq("logout")
      expect(log.extra.dig("user", "ip")).to eq(user_ip) if log.extra.present?
    end
  end
end