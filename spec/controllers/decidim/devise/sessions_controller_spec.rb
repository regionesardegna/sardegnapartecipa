# frozen_string_literal: true

require "rails_helper"


module Decidim
  module Spid
      describe SessionsController, type: :controller do
        include Decidim::Spid::Engine.routes.url_helpers
        routes do
          Decidim::Spid::Engine.routes
        end

        let(:organization) { create(:organization, default_locale: 'it') }
        let(:user) { create(:user, :confirmed, organization: organization) }

        before do
          allow(controller).to receive(:current_organization).and_return(organization)
          allow(organization).to receive(:enabled_omniauth_providers).and_return({ spid: { tenant_name: "testtenant" } })
          @request.host = organization.host
          @request.env["devise.mapping"] = ::Devise.mappings[:user]
          
          # Mock decidim_spid
          spid_routes = double("spid_routes")
          allow(controller).to receive(:decidim_spid).and_return(spid_routes)
          allow(spid_routes).to receive(:public_send).with("user_testtenant_omniauth_spslo_url").and_return("http://#{organization.host}/users/auth/testtenant/spslo")
        end

        it "effettua il logout correttamente in caso di autenticazione tramite form classico" do
          sign_in user
          delete :destroy
          expect(response).to redirect_to("/")
        end

        it "effettua il logout correttamente in caso di autenticazione tramite OmniAuth" do
          sign_in user
          session["decidim-spid.signed_in"] = true
          
          delete :destroy

          expected_url = "http://#{organization.host}/users/auth/testtenant/spslo"
          expect(response).to redirect_to(expected_url)
          expect(session["decidim-spid.signed_in"]).to be_nil
        end
      end
  end
end