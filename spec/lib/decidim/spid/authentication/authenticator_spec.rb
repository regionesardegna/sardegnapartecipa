# frozen_string_literal: true

require "rails_helper"

module Decidim
  module Spid
    module Authentication
      describe Authenticator do
        subject { described_class.new(tenant, organization, oauth_hash) }

        let(:tenant) { Decidim::Spid.tenants.find { |t| t.name == "spid" } || Decidim::Spid.tenants.first }
        let(:organization) { create(:organization) }
        let(:oauth_provider) { "spid" }
        let(:fiscal_number) { "TINIT-RSSMRA80A01H501Z" }
        let(:oauth_uid) { fiscal_number }
        let(:oauth_email) { "mario.rossi@example.org" }
        let(:oauth_name) { "Mario Rossi" }
        let(:oauth_first_name) { "Mario" }
        let(:oauth_last_name) { "Rossi" }

        let(:saml_attributes) do
          {
            "fiscalNumber" => [fiscal_number],
            "name" => [oauth_first_name],
            "familyName" => [oauth_last_name],
            "email" => [oauth_email]
          }.delete_if { |_k, v| v.first.nil? }
        end

        let(:oauth_hash) do
          {
            provider: oauth_provider,
            uid: oauth_uid,
            info: {
              email: oauth_email,
              name: oauth_name,
              first_name: oauth_first_name,
              last_name: oauth_last_name
            },
            extra: {
              raw_info: OneLogin::RubySaml::Attributes.new(saml_attributes)
            }
          }
        end

        describe "#verified_email" do
          context "flusso SPID (email certificata presente nella response SAML)" do
            it "restituisce l'email proveniente dall'asserzione SAML" do
              expect(subject.verified_email).to eq("mario.rossi@example.org")
            end
          end

          context "flusso CIE e CNS (email assente nella response SAML del Gateway)" do
            let(:oauth_email) { nil }

            it "restituisce nil" do
              expect(subject.verified_email).to be_nil
            end
          end
        end

        describe "#user_params_from_oauth_hash" do
          it "costruisce la struttura dati corretta per la registrazione" do
            expected_signature = ::Decidim::OmniauthRegistrationForm.create_signature(
              oauth_provider,
              fiscal_number
            )

            params = subject.user_params_from_oauth_hash

            expect(params[:provider]).to eq("spid")
            expect(params[:uid]).to eq(fiscal_number)
            expect(params[:name]).to eq("Mario Rossi")
            expect(params[:oauth_signature]).to eq(expected_signature)
            expect(params[:raw_data]).to eq(oauth_hash)
          end

          context "quando i dati oauth sono vuoti" do
            let(:oauth_hash) { {} }

            it "restituisce nil" do
              expect(subject.user_params_from_oauth_hash).to be_nil
            end
          end

          context "quando l'uid (codice fiscale) è vuoto" do
            let(:oauth_uid) { nil }

            it "restituisce nil" do
              expect(subject.user_params_from_oauth_hash).to be_nil
            end
          end
        end

        describe "#validate!" do
          it "restituisce true per dati SAML validi" do
            expect(subject.validate!).to be(true)
          end

          context "quando i dati SAML non sono presenti" do
            let(:oauth_hash) do
              {
                provider: oauth_provider,
                uid: oauth_uid,
                info: {}
              }
            end

            it "solleva un errore ValidationError" do
              expect { subject.validate! }.to raise_error(ValidationError, "No SAML data provided")
            end
          end
        end

        describe "#identify_user!" do
          let(:user) { create(:user, :confirmed, organization: organization) }

          it "crea una nuova Decidim::Identity con provider e codice fiscale come UID" do
            expect { subject.identify_user!(user) }.to change(Decidim::Identity, :count).by(1)

            identity = user.identities.last
            expect(identity.provider).to eq("spid")
            expect(identity.uid).to eq(fiscal_number)
            expect(identity.organization).to eq(organization)
          end

          context "quando l'identità esiste già per lo stesso utente" do
            let!(:existing_identity) do
              user.identities.create!(
                organization: organization,
                provider: oauth_provider,
                uid: fiscal_number
              )
            end

            it "restituisce l'identità esistente senza crearne una nuova" do
              expect { subject.identify_user!(user) }.not_to change(Decidim::Identity, :count)
              expect(subject.identify_user!(user)).to eq(existing_identity)
            end
          end

          context "quando l'identità con lo stesso codice fiscale è associata a un altro utente" do
            let(:other_user) { create(:user, :confirmed, organization: organization) }
            let!(:other_identity) do
              other_user.identities.create!(
                organization: organization,
                provider: oauth_provider,
                uid: fiscal_number
              )
            end

            it "solleva IdentityBoundToOtherUserError" do
              expect { subject.identify_user!(user) }.to raise_error(IdentityBoundToOtherUserError)
            end
          end
        end

        describe "#authorize_user!" do
          let(:user) { create(:user, :confirmed, organization: organization) }

          it "crea e concede (grant!) l'autorizzazione per l'utente" do
            expect { subject.authorize_user!(user) }.to change(Decidim::Authorization, :count).by(1)

            authorization = Decidim::Authorization.last
            expect(authorization.user).to eq(user)
            expect(authorization.name).to eq("#{tenant.name}_identity")
            expect(authorization.granted?).to be(true)
          end

          context "quando l'autorizzazione con la stessa firma appartiene a un altro utente" do
            let(:other_user) { create(:user, :confirmed, organization: organization) }
            let(:signature) do
              ::Decidim::OmniauthRegistrationForm.create_signature(oauth_provider, fiscal_number)
            end

            before do
              create(
                :authorization,
                user: other_user,
                name: "#{tenant.name}_identity",
                unique_id: signature
              )
            end

            it "solleva AuthorizationBoundToOtherUserError" do
              expect { subject.authorize_user!(user) }.to raise_error(AuthorizationBoundToOtherUserError)
            end
          end
        end
      end
    end
  end
end
