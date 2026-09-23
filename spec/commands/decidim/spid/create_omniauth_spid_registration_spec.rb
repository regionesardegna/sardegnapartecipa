# frozen_string_literal: true

require "rails_helper"

module Decidim
  module Spid
    describe CreateOmniauthSpidRegistration do
      let(:organization) { create(:organization) }
      let(:provider) { "spid" }
      let(:fiscal_code) { "TINIT-RSSMRA80A01H501Z" }
      let(:oauth_signature) { OmniauthRegistrationForm.create_signature(provider, fiscal_code) }
      let(:email) { "mario.rossi@example.org" }
      let(:name) { "Mario Rossi" }
      let(:nickname) { "mario_rossi" }
      let(:personal_name) { "Mario" }
      let(:surname) { "Rossi" }

      let(:form_params) do
        {
          "email" => email,
          "name" => name,
          "nickname" => nickname,
          "provider" => provider,
          "uid" => fiscal_code,
          "oauth_signature" => oauth_signature,
          "personal_name" => personal_name,
          "surname" => surname
        }
      end

      let(:form) do
        OmniauthSpidRegistrationForm.from_params(form_params).with_context(
          current_organization: organization
        )
      end

      before do
        ActionMailer::Base.deliveries.clear
      end

      describe "registrazione tramite SPID (con verified_email dal gateway SAML)" do
        let(:verified_email) { email }
        subject { described_class.new(form, verified_email) }

        it "crea l'utente, lo conferma automaticamente e associa l'identità con codice fiscale come UID" do
          expect { subject.call }.to change(Decidim::User, :count).by(1)
                                  .and change(Decidim::Identity, :count).by(1)

          user = Decidim::User.last
          identity = Decidim::Identity.last

          expect(user.email).to eq(email)
          expect(user.name).to eq("Mario Rossi")
          expect(user.nickname).to eq("mario_rossi")
          expect(user.organization).to eq(organization)
          expect(user.confirmed?).to be(true)

          expect(identity.user).to eq(user)
          expect(identity.provider).to eq("spid")
          expect(identity.uid).to eq(fiscal_code)
          expect(identity.organization).to eq(organization)
        end

        it "trasmette l'evento :ok con l'utente creato" do
          expect { subject.call }.to broadcast(:ok, an_instance_of(Decidim::User))
        end

        it "non accoda alcuna email di conferma (verified_email già certificata)" do
          expect { subject.call }.not_to have_enqueued_mail(Decidim::DecidimDeviseMailer, :confirmation_instructions)
        end

        it "memorizza correttamente i campi personal_name e surname in extended_data" do
          subject.call
          user = Decidim::User.last

          expect(user.extended_data["personal_name"]).to eq("Mario")
          expect(user.extended_data["surname"]).to eq("Rossi")
        end
      end

      describe "registrazione tramite CIE e CNS (senza verified_email dal gateway)" do
        let(:verified_email) { nil }
        subject { described_class.new(form, verified_email) }

        it "crea l'utente non confermato e invia esattamente una email di conferma" do
          expect { subject.call }.to change(Decidim::User, :count).by(1)
                                  .and change(Decidim::Identity, :count).by(1)
                                  .and have_enqueued_mail(Decidim::DecidimDeviseMailer, :confirmation_instructions).once

          user = Decidim::User.last
          identity = Decidim::Identity.last

          expect(user.email).to eq(email)
          expect(user.name).to eq("Mario Rossi")
          expect(user.confirmed?).to be(false)
          expect(identity.user).to eq(user)
          expect(identity.uid).to eq(fiscal_code)
        end

        it "memorizza i campi personal_name e surname in extended_data" do
          subject.call
          user = Decidim::User.last

          expect(user.extended_data["personal_name"]).to eq("Mario")
          expect(user.extended_data["surname"]).to eq("Rossi")
        end
      end

      describe "gestione dei campi aggiuntivi configurabili (decidim-extra_user_fields)" do
        let(:verified_email) { email }
        subject { described_class.new(form, verified_email) }

        before do
          form_params["country"] = "Italia"
          form_params["postal_code"] = "09100"
          form_params["gender"] = "male"
          form_params["date_of_birth"] = "1990-05-15"
          form_params["phone_number"] = "+393401234567"
          form_params["location"] = "Cagliari"
        end

        it "memorizza tutti i campi estesi configurabili in extended_data" do
          subject.call
          user = Decidim::User.last

          expect(user.extended_data["country"]).to eq("Italia")
          expect(user.extended_data["postal_code"]).to eq("09100")
          expect(user.extended_data["gender"]).to eq("male")
          expect(user.extended_data["date_of_birth"]).to eq("1990-05-15")
          expect(user.extended_data["phone_number"]).to eq("+393401234567")
          expect(user.extended_data["location"]).to eq("Cagliari")
          expect(user.extended_data["personal_name"]).to eq("Mario")
          expect(user.extended_data["surname"]).to eq("Rossi")
        end
      end

      describe "gestione di utenti minorenni e rappresentante legale" do
        let(:verified_email) { email }
        subject { described_class.new(form, verified_email) }

        before do
          form_params["date_of_birth"] = "2010-01-01"
          form_params["underage"] = "1"
          form_params["statutory_representative_email"] = "genitore@example.org"
        end

        it "memorizza i dati del rappresentante legale in extended_data" do
          subject.call
          user = Decidim::User.last

          expect(user.extended_data["underage"]).to eq("1")
          expect(user.extended_data["statutory_representative_email"]).to eq("genitore@example.org")
        end
      end

      describe "utente già registrato / identità già esistente" do
        let(:verified_email) { email }
        let!(:existing_user) do
          create(
            :user,
            :confirmed,
            organization: organization,
            email: email,
            name: "Mario Rossi"
          )
        end
        let!(:existing_identity) do
          create(
            :identity,
            user: existing_user,
            organization: organization,
            provider: provider,
            uid: fiscal_code
          )
        end

        subject { described_class.new(form, verified_email) }

        it "trasmette :ok con l'utente esistente e non crea nuovi record" do
          expect { subject.call }.to change(Decidim::User, :count).by(0)
          expect { subject.call }.to change(Decidim::Identity, :count).by(0)
          expect { subject.call }.to broadcast(:ok, existing_user)
        end

        context "quando l'utente esistente non era confermato e si registra con email verificata" do
          before do
            existing_user.update_columns(confirmed_at: nil)
          end

          it "conferma l'utente esistente" do
            subject.call
            expect(existing_user.reload.confirmed?).to be(true)
          end
        end
      end

      describe "sicurezza e validazione della firma OAuth" do
        let(:verified_email) { email }
        subject { described_class.new(form, verified_email) }

        context "quando la signature OAuth non è valida o manomessa" do
          before do
            form_params["oauth_signature"] = "invalid_signature"
          end

          it "solleva un'eccezione Decidim::InvalidOauthSignature" do
            expect { subject.call }.to raise_error(Decidim::InvalidOauthSignature)
          end
        end
      end

      describe "validazione e gestione degli errori" do
        let(:verified_email) { nil }
        subject { described_class.new(form, verified_email) }

        context "quando il form non è valido (email vuota per CIE/CNS)" do
          before do
            form_params["email"] = ""
          end

          it "trasmette :invalid e non crea alcun utente" do
            expect { subject.call }.to broadcast(:invalid)
            expect { subject.call }.to change(Decidim::User, :count).by(0)
          end
        end

        context "quando l'email è già in uso da un altro utente nella stessa organizzazione" do
          let!(:other_user) do
            create(
              :user,
              :confirmed,
              organization: organization,
              email: email
            )
          end

          it "trasmette l'evento :error e non crea duplicati" do
            expect { subject.call }.to broadcast(:error, an_instance_of(Decidim::User))
            expect { subject.call }.to change(Decidim::Identity, :count).by(0)
          end
        end
      end
    end
  end
end
