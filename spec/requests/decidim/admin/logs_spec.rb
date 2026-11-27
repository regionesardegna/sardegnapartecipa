# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin logs", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:organization) { create(:organization) }
  let(:admin) { create(:user, :admin, :confirmed, organization:) }
  let(:regular_user) { create(:user, :confirmed, name: "Mario Rossi", organization:) }

  let!(:login_log) do
    Decidim::ActionLogger.log(
      :login,
      regular_user,
      regular_user,
      nil,
      visibility: "admin-only"
    ).tap { |log| log.update_column(:created_at, Time.zone.parse("2026-11-20 10:00:00")) }
  end

  let!(:logout_log) do
    Decidim::ActionLogger.log(
      :logout,
      admin,
      admin,
      nil,
      visibility: "admin-only"
    ).tap { |log| log.update_column(:created_at, Time.zone.parse("2026-11-25 15:00:00")) }
  end

  before do
    https!
    host! organization.host
    sign_in admin
  end

  describe "GET /admin/logs" do
    it "carica la pagina dei registri senza errori di Ransack o paginazione" do
      get decidim_admin.logs_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Mario Rossi")
    end

    it "filtra tramite il campo di ricerca testuale Ransack" do
      get decidim_admin.logs_path, params: {
        q: { user_name_or_user_nickname_or_user_email_cont: "Mario Rossi" }
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Mario Rossi")
      expect(response.body).not_to include(admin.name)
    end

    it "filtra per tipo evento e intervallo date tramite _identity_filters" do
      get decidim_admin.logs_path, params: {
        q: {
          action_type: "login",
          from: "2026-11-19",
          to: "2026-11-21"
        }
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Mario Rossi")
      expect(response.body).not_to include(admin.name)
    end
  end
end
