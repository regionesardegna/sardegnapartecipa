# frozen_string_literal: true

require "rails_helper"

module Decidim
  module Spid
    describe OmniauthCallbacksController, type: :controller do
      routes do
        ActionDispatch::Routing::RouteSet.new.tap do |r|
          r.draw do
            post "users/auth/spid/create", to: "decidim/spid/omniauth_callbacks#create"
          end
        end
      end

      let(:organization) { create(:organization) }
      let(:provider) { "spid" }
      let(:fiscal_code) { "TINIT-RSSMRA80A01H501Z" }
      let(:oauth_signature) { OmniauthRegistrationForm.create_signature(provider, fiscal_code) }
      let(:email) { "mario.rossi@example.org" }
      let(:name) { "Mario Rossi" }
      let(:nickname) { "mario_rossi" }
      let(:personal_name) { "Mario" }
      let(:surname) { "Rossi" }

      let(:raw_data) do
        {
          provider: provider,
          uid: fiscal_code,
          info: {
            name: name,
            email: oauth_email
          }
        }
      end

      before do
        @request.host = organization.host
        @request.env["devise.mapping"] = ::Devise.mappings[:user]
        @request.env["decidim.current_organization"] = organization
        session["tenant-spid-name"] = "spid"
        session["spid-uid"] = fiscal_code
      end

      describe "POST create" do
        context "flusso SPID (con email verificata)" do
          let(:oauth_email) { email }

          it "autentica e reindirizza l'utente confermato senza inviare email di conferma" do
            post :create, params: {
              user: {
                provider: provider,
                uid: fiscal_code,
                name: name,
                nickname: nickname,
                email: email,
                oauth_signature: oauth_signature,
                personal_name: personal_name,
                surname: surname,
                raw_data: raw_data.to_json
              }
            }

            expect(response).to redirect_to("/")
            expect(flash[:notice]).to be_present

            user = Decidim::User.find_by(email: email)
            expect(user).to be_present
            expect(user.confirmed?).to be(true)
            expect(user.extended_data["personal_name"]).to eq("Mario")
            expect(user.extended_data["surname"]).to eq("Rossi")
          end
        end

        context "flusso CIE e CNS (senza email verificata da SAML)" do
          let(:oauth_email) { nil }

          it "crea l'utente non confermato, reindirizza alla root con avviso e accoda esattamente una mail di conferma" do
            expect do
              post :create, params: {
                user: {
                  provider: provider,
                  uid: fiscal_code,
                  name: name,
                  nickname: nickname,
                  email: email,
                  oauth_signature: oauth_signature,
                  personal_name: personal_name,
                  surname: surname,
                  raw_data: raw_data.to_json
                }
              }
            end.to have_enqueued_mail(Decidim::DecidimDeviseMailer, :confirmation_instructions).once

            expect(response).to redirect_to("/")
            expect(flash[:notice]).to be_present
            expect(flash[:notice]).to eq(I18n.t("devise.registrations.signed_up_but_unconfirmed", locale: organization.default_locale))

            user = Decidim::User.find_by(email: email)
            expect(user).to be_present
            expect(user.confirmed?).to be(false)
            expect(user.extended_data["personal_name"]).to eq("Mario")
            expect(user.extended_data["surname"]).to eq("Rossi")
          end
        end
      end
    end
  end
end
