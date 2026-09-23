# frozen_string_literal: true

require "rails_helper"

RSpec.describe Decidim::CreateRegistration, type: :command do
  let(:extra_user_fields_config) do
    { "enabled" => false }
  end
  let(:organization) do
    create(
      :organization,
      host: "partecipa.sardegna.it",
      extra_user_fields: extra_user_fields_config
    )
  end
  let(:valid_password) { "ABCDEFGHIL1_?a" }
  let(:form_params) do
    {
      name: "Mario Rossi",
      email: "mario.rossi@example.org",
      password: valid_password,
      password_confirmation: valid_password,
      tos_agreement: "1",
      newsletter: "1",
      current_locale: "it"
    }
  end

  let(:form) do
    Decidim::RegistrationForm.from_params(form_params).with_context(
      current_organization: organization,
      current_locale: "it"
    )
  end

  subject { described_class.new(form) }

  describe "registrazione utente con esito positivo" do
    context "quando extra_user_fields è disabilitato" do
      it "crea con successo l'utente e trasmette l'evento :ok" do
        expect { subject.call }.to broadcast(:ok)
          .and change(Decidim::User, :count).by(1)
      end

      it "imposta correttamente tutti gli attributi dell'utente" do
        subject.call

        user = Decidim::User.find_by(email: "mario.rossi@example.org")
        expect(user).to be_present
        expect(user.name).to eq("Mario Rossi")
        expect(user.nickname).to be_present
        expect(user.organization).to eq(organization)
        expect(user.locale).to eq("it")
        expect(user.accepted_tos_version).to be_within(1.second).of(organization.tos_version)
        expect(user.tos_accepted?).to be(true)
        expect(user.newsletter_notifications_at).to be_present
        expect(user.password_updated_at).to be_present
        expect(user.valid_password?(valid_password)).to be(true)
      end
    end

    context "quando sono abilitati i campi personal_name e surname di Sardegna Partecipa" do
      let(:extra_user_fields_config) do
        {
          "enabled" => true,
          "personal_name" => { "enabled" => true },
          "surname" => { "enabled" => true }
        }
      end

      before do
        form_params[:personal_name] = "Mario"
        form_params[:surname] = "Rossi"
      end

      it "crea l'utente, trasmette :ok e memorizza personal_name e surname in extended_data" do
        expect { subject.call }.to broadcast(:ok)
          .and change(Decidim::User, :count).by(1)

        user = Decidim::User.find_by(email: "mario.rossi@example.org")
        expect(user).to be_present
        expect(user.extended_data).to be_present
        expect(user.extended_data["personal_name"]).to eq("Mario")
        expect(user.extended_data["surname"]).to eq("Rossi")
      end
    end

    context "quando sono abilitati tutti i campi estesi della gemma e di Sardegna Partecipa" do
      let(:extra_user_fields_config) do
        {
          "enabled" => true,
          "country" => { "enabled" => true },
          "postal_code" => { "enabled" => true },
          "gender" => { "enabled" => true },
          "date_of_birth" => { "enabled" => true },
          "phone_number" => { "enabled" => true },
          "location" => { "enabled" => true },
          "underage" => { "enabled" => true },
          "underage_limit" => 18,
          "personal_name" => { "enabled" => true },
          "surname" => { "enabled" => true }
        }
      end

      before do
        form_params[:personal_name] = "Mario"
        form_params[:surname] = "Rossi"
        form_params[:country] = "Italia"
        form_params[:postal_code] = "09100"
        form_params[:gender] = "male"
        form_params[:date_of_birth] = "2010-01-01"
        form_params[:phone_number] = "+393401234567"
        form_params[:location] = "Cagliari"
        form_params[:underage] = "1"
        form_params[:statutory_representative_email] = "genitore@example.org"
      end

      it "salva correttamente tutti i campi estesi in extended_data" do
        expect { subject.call }.to broadcast(:ok)
          .and change(Decidim::User, :count).by(1)

        user = Decidim::User.find_by(email: "mario.rossi@example.org")
        expect(user).to be_present
        expect(user.extended_data["country"]).to eq("Italia")
        expect(user.extended_data["postal_code"]).to eq("09100")
        expect(user.extended_data["gender"]).to eq("male")
        expect(user.extended_data["phone_number"]).to eq("+393401234567")
        expect(user.extended_data["location"]).to eq("Cagliari")
        expect(user.extended_data["underage"]).to eq(true).or eq("1")
        expect(user.extended_data["statutory_representative_email"]).to eq("genitore@example.org")
        expect(user.extended_data["personal_name"]).to eq("Mario")
        expect(user.extended_data["surname"]).to eq("Rossi")
        expect(user.extended_data["date_of_birth"]).to be_present
      end

      it "invia l'email al rappresentante legale per utenti minorenni" do
        mailer_double = double(deliver_later: true)
        expect(Decidim::ExtraUserFields::StatutoryRepresentativeMailer).to receive(:inform).and_return(mailer_double)

        subject.call
      end
    end
  end

  describe "gestione degli errori di registrazione" do
    context "quando il form non è valido" do
      before do
        form_params[:email] = "formato-errato"
      end

      it "trasmette l'evento :invalid e non crea l'utente" do
        expect { subject.call }.to broadcast(:invalid)
        expect { subject.call }.not_to change(Decidim::User, :count)
      end
    end

    context "quando la password non rispetta i criteri di complessità di Sardegna Partecipa" do
      before do
        form_params[:password] = "semplice"
        form_params[:password_confirmation] = "semplice"
      end

      it "trasmette l'evento :invalid e non crea l'utente" do
        expect { subject.call }.to broadcast(:invalid)
        expect { subject.call }.not_to change(Decidim::User, :count)
      end
    end

    context "quando i campi aggiuntivi obbligatori mancano" do
      let(:extra_user_fields_config) do
        {
          "enabled" => true,
          "personal_name" => { "enabled" => true },
          "surname" => { "enabled" => true }
        }
      end

      it "trasmette :invalid se personal_name o surname sono assenti" do
        expect { subject.call }.to broadcast(:invalid)
        expect { subject.call }.not_to change(Decidim::User, :count)
      end
    end

    context "quando l'email del rappresentante legale coincide con l'email dell'utente" do
      let(:extra_user_fields_config) do
        {
          "enabled" => true,
          "date_of_birth" => { "enabled" => true },
          "underage" => { "enabled" => true },
          "underage_limit" => 18
        }
      end

      before do
        form_params[:date_of_birth] = "2010-01-01"
        form_params[:underage] = "1"
        form_params[:statutory_representative_email] = "mario.rossi@example.org"
      end

      it "trasmette :invalid e non crea l'utente" do
        expect { subject.call }.to broadcast(:invalid)
        expect { subject.call }.not_to change(Decidim::User, :count)
      end
    end

    context "quando l'email è già in uso nella stessa organizzazione" do
      let!(:existing_user) do
        create(
          :user,
          organization: organization,
          email: "mario.rossi@example.org"
        )
      end

      it "trasmette l'evento :invalid e non crea un utente duplicato" do
        expect { subject.call }.to broadcast(:invalid)
        expect { subject.call }.not_to change(Decidim::User, :count)
      end
    end
  end
end
