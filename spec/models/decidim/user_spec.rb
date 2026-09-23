# frozen_string_literal: true

require "rails_helper"

RSpec.describe Decidim::User, type: :model do
  let(:organization) { create(:organization, host: "partecipa.sardegna.it") }
  let(:valid_password) { "ABCDEFGHIL1_?a" }
  let!(:user) do
    create(
      :user,
      organization: organization,
      email: "cittadino@example.org",
      password: valid_password,
      password_confirmation: valid_password
    )
  end

  describe "validazioni della password sul modello utente" do
    it "è valido con il modello di password di Sardegna Partecipa 'ABCDEFGHIL1_?a'" do
      expect(user).to be_valid
      expect(user).to be_persisted
    end

    it "è invalido se la password ha meno di 12 caratteri" do
      invalid_user = build(
        :user,
        organization: organization,
        password: "Abc1!defghi", # 11 caratteri
        password_confirmation: "Abc1!defghi"
      )
      expect(invalid_user).not_to be_valid
      expect(invalid_user.errors[:password]).to include(I18n.t("password_validator.password_too_short"))
    end

    it "è invalido se la password non contiene lettere maiuscole" do
      invalid_user = build(
        :user,
        organization: organization,
        password: "abcdefghil1_?a",
        password_confirmation: "abcdefghil1_?a"
      )
      I18n.with_locale(:it) do
        expect(invalid_user).not_to be_valid
        expect(invalid_user.errors[:password]).to include("deve contenere almeno una lettera maiuscola")
      end
    end

    it "è invalido se la password non contiene lettere minuscole" do
      invalid_user = build(
        :user,
        organization: organization,
        password: "ABCDEFGHIL1_?A",
        password_confirmation: "ABCDEFGHIL1_?A"
      )
      I18n.with_locale(:it) do
        expect(invalid_user).not_to be_valid
        expect(invalid_user.errors[:password]).to include("deve contenere almeno una lettera minuscola")
      end
    end

    it "è invalido se la password non contiene numeri" do
      invalid_user = build(
        :user,
        organization: organization,
        password: "ABCDEFGHIL__?a",
        password_confirmation: "ABCDEFGHIL__?a"
      )
      I18n.with_locale(:it) do
        expect(invalid_user).not_to be_valid
        expect(invalid_user.errors[:password]).to include("deve contenere almeno un numero")
      end
    end

    it "è invalido se la password non contiene caratteri speciali" do
      invalid_user = build(
        :user,
        organization: organization,
        password: "ABCDEFGHIL123a",
        password_confirmation: "ABCDEFGHIL123a"
      )
      I18n.with_locale(:it) do
        expect(invalid_user).not_to be_valid
        expect(invalid_user.errors[:password]).to include("deve contenere almeno un simbolo speciale (!@#$%^&*)")
      end
    end
  end

  describe "autenticazione classica (email e password)" do
    describe "#valid_password?" do
      it "autentica con successo l'utente con la password corretta" do
        expect(user.valid_password?(valid_password)).to be(true)
      end

      it "rifiuta l'autenticazione in caso di password errata" do
        expect(user.valid_password?("WrongPassword123!")).to be(false)
        expect(user.valid_password?("abcdefghil1_?a")).to be(false) # case sensitive
        expect(user.valid_password?("")).to be(false)
      end
    end

    describe "ricerca per autenticazione (.find_for_authentication)" do
      it "trova l'utente corretto all'interno della stessa organizzazione tramite email" do
        found_user = described_class.find_for_authentication(
          env: { "decidim.current_organization" => organization },
          email: "cittadino@example.org"
        )
        expect(found_user).to eq(user)
      end

      it "gestisce la ricerca email in modo case-insensitive" do
        found_user = described_class.find_for_authentication(
          env: { "decidim.current_organization" => organization },
          email: "CITTADINO@EXAMPLE.ORG"
        )
        expect(found_user).to eq(user)
      end

      it "non trova l'utente se l'email appartiene a un'altra organizzazione (isolamento tenant)" do
        other_org = create(:organization, host: "altra.sardegna.it")
        found_user = described_class.find_for_authentication(
          env: { "decidim.current_organization" => other_org },
          email: "cittadino@example.org"
        )
        expect(found_user).to be_nil
      end

      it "non trova alcun utente in caso di email inesistente" do
        found_user = described_class.find_for_authentication(
          env: { "decidim.current_organization" => organization },
          email: "non.esisto@example.org"
        )
        expect(found_user).to be_nil
      end
    end

    describe "stato dell'account e abilitazione all'autenticazione (#active_for_authentication?)" do
      it "consente l'accesso a un utente attivo e confermato" do
        user.confirm
        expect(user.confirmed?).to be(true)
        expect(user.active_for_authentication?).to be(true)
      end

      it "non consente l'accesso se l'utente è bloccato" do
        user.blocked = true
        expect(user.active_for_authentication?).to be(false)
      end

      it "non consente l'accesso se l'account è stato eliminato" do
        user.deleted_at = Time.current
        expect(user.active_for_authentication?).to be(false)
      end
    end

    describe "aggiornamento della password" do
      it "consente l'aggiornamento con una nuova password conforme" do
        new_valid_password = "NuovaPassword123!_#"
        user.password = new_valid_password
        user.password_confirmation = new_valid_password

        expect(user.save).to be(true)
        expect(user.reload.valid_password?(new_valid_password)).to be(true)
        expect(user.valid_password?(valid_password)).to be(false)
      end

      it "impedisce l'aggiornamento se la nuova password non rispetta i vincoli di complessità" do
        user.password = "nuovasemplice"
        user.password_confirmation = "nuovasemplice"

        expect(user.save).to be(false)
        expect(user.errors[:password]).not_to be_empty
      end
    end
  end
end
