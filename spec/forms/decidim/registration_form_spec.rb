# frozen_string_literal: true

require "rails_helper"

RSpec.describe Decidim::RegistrationForm, type: :form do
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
  let(:params) do
    {
      name: "Mario Rossi",
      nickname: "mariorossi",
      email: "mario.rossi@example.org",
      password: valid_password,
      password_confirmation: valid_password,
      tos_agreement: "1"
    }
  end

  subject do
    described_class.from_params(params).with_context(current_organization: organization)
  end

  describe "validazione di base e campi standard di registrazione" do
    it "è valido con dati standard corretti" do
      expect(subject).to be_valid
    end

    it "è invalido senza il nome" do
      params[:name] = ""
      expect(subject).not_to be_valid
      expect(subject.errors[:name]).to be_present
    end

    it "è invalido con un nome che contiene caratteri vietati (<, >, etc.)" do
      params[:name] = "Mario <script>"
      expect(subject).not_to be_valid
      expect(subject.errors[:name]).to be_present
    end

    it "è invalido senza l'email" do
      params[:email] = ""
      expect(subject).not_to be_valid
      expect(subject.errors[:email]).to be_present
    end

    it "è invalido con un formato email non valido" do
      params[:email] = "non-un-email"
      expect(subject).not_to be_valid
      expect(subject.errors[:email]).to be_present
    end

    it "è invalido se l'accettazione dei termini (tos_agreement) non è spuntata" do
      params[:tos_agreement] = "0"
      expect(subject).not_to be_valid
      expect(subject.errors[:tos_agreement]).to be_present
    end

    describe "generazione automatica del nickname" do
      it "genera il nickname a partire dal nome e dall'organizzazione" do
        expect(subject.nickname).to be_present
        expect(subject.nickname).to start_with("mario")
      end
    end

    describe "unicità di email all'interno dell'organizzazione" do
      let!(:existing_user) do
        create(
          :user,
          organization: organization,
          email: "mario.rossi@example.org"
        )
      end

      it "è invalido se l'email è già registrata nella stessa organizzazione" do
        params[:email] = "mario.rossi@example.org"
        expect(subject).not_to be_valid
        expect(subject.errors[:email]).to include(I18n.t("errors.messages.taken"))
      end

      it "è valido se la stessa email appartiene a un'altra organizzazione (isolamento tenant)" do
        other_org = create(:organization, host: "altra.sardegna.it")
        other_subject = described_class.from_params(params).with_context(current_organization: other_org)
        expect(other_subject).to be_valid
      end
    end
  end

  describe "validazione della password nel form" do
    it "è valido con password conforme al modello 'ABCDEFGHIL1_?a'" do
      expect(subject).to be_valid
    end

    it "è invalido se la password è vuota" do
      params[:password] = ""
      params[:password_confirmation] = ""
      expect(subject).not_to be_valid
      expect(subject.errors[:password]).to include(I18n.t("errors.messages.blank"))
    end

    it "è invalido se la password ha meno di 12 caratteri" do
      params[:password] = "Abc1!defghi" # 11 caratteri
      params[:password_confirmation] = "Abc1!defghi"
      expect(subject).not_to be_valid
      expect(subject.errors[:password]).to include(I18n.t("password_validator.password_too_short"))
    end

    it "è invalido se la password non contiene lettere maiuscole" do
      params[:password] = "abcdefghil1_?a"
      params[:password_confirmation] = "abcdefghil1_?a"
      I18n.with_locale(:it) do
        expect(subject).not_to be_valid
        expect(subject.errors[:password]).to include("deve contenere almeno una lettera maiuscola")
      end
    end

    it "è invalido se la password non contiene lettere minuscole" do
      params[:password] = "ABCDEFGHIL1_?A"
      params[:password_confirmation] = "ABCDEFGHIL1_?A"
      I18n.with_locale(:it) do
        expect(subject).not_to be_valid
        expect(subject.errors[:password]).to include("deve contenere almeno una lettera minuscola")
      end
    end

    it "è invalido se la password non contiene numeri" do
      params[:password] = "ABCDEFGHIL__?a"
      params[:password_confirmation] = "ABCDEFGHIL__?a"
      I18n.with_locale(:it) do
        expect(subject).not_to be_valid
        expect(subject.errors[:password]).to include("deve contenere almeno un numero")
      end
    end

    it "è invalido se la password non contiene simboli speciali" do
      params[:password] = "ABCDEFGHIL123a"
      params[:password_confirmation] = "ABCDEFGHIL123a"
      I18n.with_locale(:it) do
        expect(subject).not_to be_valid
        expect(subject.errors[:password]).to include("deve contenere almeno un simbolo speciale (!@#$%^&*)")
      end
    end
  end

  describe "quando extra_user_fields è disabilitato" do
    let(:extra_user_fields_config) { { "enabled" => false } }

    it "non richiede i campi aggiuntivi" do
      expect(subject).to be_valid
    end
  end

  describe "campi aggiuntivi specifici di Sardegna Partecipa (personal_name e surname)" do
    let(:extra_user_fields_config) do
      {
        "enabled" => true,
        "personal_name" => { "enabled" => true },
        "surname" => { "enabled" => true }
      }
    end

    context "quando personal_name e surname sono forniti correttamente" do
      before do
        params[:personal_name] = "Mario"
        params[:surname] = "Rossi"
      end

      it "è valido con nomi e cognomi standard" do
        expect(subject).to be_valid
      end

      it "è valido con cognomi o nomi composti contenenti spazi" do
        params[:personal_name] = "Maria Teresa"
        params[:surname] = "De Rossi"
        expect(subject).to be_valid
      end

      it "è valido con nomi o cognomi contenenti apostrofi" do
        params[:personal_name] = "Sant'Anna"
        params[:surname] = "D'Angelo"
        expect(subject).to be_valid
      end
    end

    context "validazioni di presenza" do
      it "è invalido se personal_name è mancante" do
        params[:personal_name] = ""
        params[:surname] = "Rossi"
        expect(subject).not_to be_valid
        expect(subject.errors[:personal_name]).to be_present
      end

      it "è invalido se surname è mancante" do
        params[:personal_name] = "Mario"
        params[:surname] = ""
        expect(subject).not_to be_valid
        expect(subject.errors[:surname]).to be_present
      end
    end

    context "validazioni di formato (/\\A[a-zA-Z' ]+\\z/)" do
      it "è invalido se personal_name contiene numeri" do
        params[:personal_name] = "Mario123"
        params[:surname] = "Rossi"
        expect(subject).not_to be_valid
        expect(subject.errors[:personal_name]).to include(I18n.t("errors.messages.invalid"))
      end

      it "è invalido se personal_name contiene caratteri speciali non consentiti" do
        params[:personal_name] = "Mario@!"
        params[:surname] = "Rossi"
        expect(subject).not_to be_valid
        expect(subject.errors[:personal_name]).to include(I18n.t("errors.messages.invalid"))
      end

      it "è invalido se surname contiene numeri" do
        params[:personal_name] = "Mario"
        params[:surname] = "Rossi99"
        expect(subject).not_to be_valid
        expect(subject.errors[:surname]).to include(I18n.t("errors.messages.invalid"))
      end

      it "è invalido se surname contiene caratteri speciali non consentiti" do
        params[:personal_name] = "Mario"
        params[:surname] = "Rossi#?"
        expect(subject).not_to be_valid
        expect(subject.errors[:surname]).to include(I18n.t("errors.messages.invalid"))
      end
    end
  end

  describe "campi aggiuntivi opzionali della gemma configurabili da admin" do
    context "quando il campo country è abilitato" do
      let(:extra_user_fields_config) do
        {
          "enabled" => true,
          "country" => { "enabled" => true }
        }
      end

      it "è invalido se country è vuoto" do
        params[:country] = ""
        expect(subject).not_to be_valid
        expect(subject.errors[:country]).to be_present
      end

      it "è valido quando country è compilato" do
        params[:country] = "Italia"
        expect(subject).to be_valid
      end
    end

    context "quando il campo postal_code è abilitato" do
      let(:extra_user_fields_config) do
        {
          "enabled" => true,
          "postal_code" => { "enabled" => true }
        }
      end

      it "è invalido se postal_code è vuoto" do
        params[:postal_code] = ""
        expect(subject).not_to be_valid
        expect(subject.errors[:postal_code]).to be_present
      end

      it "è valido quando postal_code è compilato" do
        params[:postal_code] = "09100"
        expect(subject).to be_valid
      end
    end

    context "quando il campo gender è abilitato" do
      let(:extra_user_fields_config) do
        {
          "enabled" => true,
          "gender" => { "enabled" => true }
        }
      end

      it "è invalido se gender è vuoto o non compreso tra i valori consentiti" do
        params[:gender] = "non_valido"
        expect(subject).not_to be_valid
        expect(subject.errors[:gender]).to be_present
      end

      it "è valido con un'opzione di genere consentita" do
        Decidim::ExtraUserFields::Engine::DEFAULT_GENDER_OPTIONS.each do |option|
          params[:gender] = option.to_s
          expect(described_class.from_params(params).with_context(current_organization: organization)).to be_valid
        end
      end
    end

    context "quando il campo date_of_birth è abilitato" do
      let(:extra_user_fields_config) do
        {
          "enabled" => true,
          "date_of_birth" => { "enabled" => true }
        }
      end

      it "è invalido se date_of_birth è vuoto" do
        params[:date_of_birth] = ""
        expect(subject).not_to be_valid
        expect(subject.errors[:date_of_birth]).to be_present
      end

      it "è valido se date_of_birth è una data valida" do
        params[:date_of_birth] = "1990-05-15"
        expect(subject).to be_valid
      end
    end

    context "quando il campo phone_number è abilitato con pattern regex" do
      let(:extra_user_fields_config) do
        {
          "enabled" => true,
          "phone_number" => {
            "enabled" => true,
            "pattern" => "\\A\\+39[0-9]{9,10}\\z"
          }
        }
      end

      it "è invalido se non rispetta il pattern telefonico configurato" do
        params[:phone_number] = "12345"
        expect(subject).not_to be_valid
        expect(subject.errors[:phone_number]).to be_present
      end

      it "è valido con un numero di telefono conforme al pattern" do
        params[:phone_number] = "+393401234567"
        expect(subject).to be_valid
      end
    end

    context "quando i campi underage e statutory_representative_email sono abilitati" do
      let(:extra_user_fields_config) do
        {
          "enabled" => true,
          "date_of_birth" => { "enabled" => true },
          "underage" => { "enabled" => true },
          "underage_limit" => 18
        }
      end

      it "è valido per un maggiorenne senza email del rappresentante" do
        params[:date_of_birth] = 20.years.ago.to_date.to_s
        params[:underage] = "0"
        expect(subject).to be_valid
      end

      it "è invalido se un minorenne non fornisce l'email del rappresentante legale" do
        params[:date_of_birth] = 15.years.ago.to_date.to_s
        params[:underage] = "1"
        params[:statutory_representative_email] = ""
        expect(subject).not_to be_valid
        expect(subject.errors[:statutory_representative_email]).to be_present
      end

      it "è valido se un minorenne fornisce l'email del rappresentante legale" do
        params[:date_of_birth] = 15.years.ago.to_date.to_s
        params[:underage] = "1"
        params[:statutory_representative_email] = "genitore@example.org"
        expect(subject).to be_valid
      end

      it "è invalido se dichiara di essere minorenne ma la data di nascita indica maggiorenne" do
        params[:date_of_birth] = 25.years.ago.to_date.to_s
        params[:underage] = "1"
        params[:statutory_representative_email] = "genitore@example.org"
        expect(subject).not_to be_valid
        expect(subject.errors[:date_of_birth]).to be_present
      end
    end
  end
end
