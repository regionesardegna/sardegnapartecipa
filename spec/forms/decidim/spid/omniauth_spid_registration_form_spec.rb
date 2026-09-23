# frozen_string_literal: true

require "rails_helper"

module Decidim
  module Spid
    describe OmniauthSpidRegistrationForm do
      subject do
        described_class.from_params(params).with_context(
          current_organization: organization
        )
      end

      let(:organization) { create(:organization, extra_user_fields: extra_user_fields_config) }
      let(:extra_user_fields_config) do
        {
          "enabled" => true,
          "personal_name" => { "enabled" => true },
          "surname" => { "enabled" => true }
        }
      end

      let(:email) { "mario.rossi@example.org" }
      let(:name) { "Mario Rossi" }
      let(:nickname) { "mario_rossi" }
      let(:provider) { "spid" }
      let(:uid) { "TINIT-RSSMRA80A01H501Z" }
      let(:personal_name) { "Mario" }
      let(:surname) { "Rossi" }
      let(:oauth_signature) { OmniauthRegistrationForm.create_signature(provider, uid) }

      let(:params) do
        {
          "email" => email,
          "name" => name,
          "nickname" => nickname,
          "provider" => provider,
          "uid" => uid,
          "oauth_signature" => oauth_signature,
          "personal_name" => personal_name,
          "surname" => surname
        }
      end

      describe "validazione dei campi obbligatori di base" do
        it "è valido con parametri completi e corretti" do
          expect(subject).to be_valid
        end

        it "è invalido se l'email è assente" do
          params["email"] = ""
          expect(subject).to be_invalid
          expect(subject.errors[:email]).to be_present
        end

        it "è invalido se il nome è assente" do
          params["name"] = ""
          expect(subject).to be_invalid
          expect(subject.errors[:name]).to be_present
        end

        it "è invalido se il nickname è assente" do
          params["nickname"] = ""
          expect(subject).to be_invalid
          expect(subject.errors[:nickname]).to be_present
        end

        it "è invalido se il provider è assente" do
          params["provider"] = ""
          expect(subject).to be_invalid
          expect(subject.errors[:provider]).to be_present
        end

        it "è invalido se l'uid (codice fiscale) è assente" do
          params["uid"] = ""
          expect(subject).to be_invalid
          expect(subject.errors[:uid]).to be_present
        end
      end

      describe "campi aggiuntivi personal_name e surname di Sardegna Partecipa" do
        context "quando personal_name contiene caratteri non consentiti (numeri o simboli)" do
          it "è invalido con numeri" do
            params["personal_name"] = "Mario123"
            expect(subject).to be_invalid
            expect(subject.errors[:personal_name]).to be_present
          end

          it "è invalido con caratteri speciali non ammessi" do
            params["personal_name"] = "Mario@Rossi"
            expect(subject).to be_invalid
            expect(subject.errors[:personal_name]).to be_present
          end

          it "è valido con lettere, spazi e apostrofi" do
            params["personal_name"] = "Gian Luca D'Annunzio"
            expect(subject).to be_valid
          end
        end

        context "quando surname contiene caratteri non consentiti" do
          it "è invalido con numeri" do
            params["surname"] = "Rossi99"
            expect(subject).to be_invalid
            expect(subject.errors[:surname]).to be_present
          end

          it "è valido con apostrofo e spazi" do
            params["surname"] = "De' Medici"
            expect(subject).to be_valid
          end
        end

        context "quando personal_name o surname sono vuoti ed extra_user_fields è attivo" do
          it "è invalido se personal_name è vuoto" do
            params["personal_name"] = ""
            expect(subject).to be_invalid
            expect(subject.errors[:personal_name]).to be_present
          end

          it "è invalido se surname è vuoto" do
            params["surname"] = ""
            expect(subject).to be_invalid
            expect(subject.errors[:surname]).to be_present
          end
        end
      end

      describe "campi configurabili aggiuntivi (decidim-extra_user_fields)" do
        let(:extra_user_fields_config) do
          {
            "enabled" => true,
            "personal_name" => { "enabled" => true },
            "surname" => { "enabled" => true },
            "gender" => { "enabled" => true },
            "date_of_birth" => { "enabled" => true },
            "postal_code" => { "enabled" => true },
            "country" => { "enabled" => true }
          }
        end

        before do
          params["gender"] = "female"
          params["date_of_birth"] = "1992-08-20"
          params["postal_code"] = "09124"
          params["country"] = "Italia"
        end

        it "è valido se tutti i campi configurati sono forniti correttamente" do
          expect(subject).to be_valid
        end

        it "è invalido se un campo obbligatorio abilitato (es. gender) è assente" do
          params["gender"] = ""
          expect(subject).to be_invalid
          expect(subject.errors[:gender]).to be_present
        end
      end

      describe "#normalized_nickname" do
        it "restituisce il nickname specificato" do
          expect(subject.normalized_nickname).to eq("mario_rossi")
        end
      end
    end
  end
end
