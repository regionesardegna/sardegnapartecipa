# frozen_string_literal: true

require "rails_helper"

RSpec.describe PasswordValidator, type: :validator do
  let(:validator) { described_class.new(attributes: [:password]) }
  let(:organization) { create(:organization, host: "partecipa.sardegna.it") }
  let(:user) do
    build(
      :user,
      name: "Mario Rossi",
      nickname: "mariorossi",
      email: "mario.rossi@example.org",
      organization: organization
    )
  end

  # Helper per eseguire la validazione
  def validate_password(password, record = user)
    record.password = password
    record.errors.clear
    validator.validate_each(record, :password, password)
  end

  describe "modello di riferimento 'ABCDEFGHIL1_?a'" do
    it "è valido e rispetta tutti i criteri di complessità di Sardegna Partecipa" do
      expect(validate_password("ABCDEFGHIL1_?a")).to be(true)
      expect(user.errors[:password]).to be_empty
    end
  end

  describe "lunghezza minima e massima" do
    it "è invalida se inferiore a 12 caratteri (nuovo minimo Sardegna Partecipa)" do
      # 11 caratteri: contiene maiuscola, minuscola, numero, simbolo
      expect(validate_password("Abcde1!fghi")).to be(false)
      expect(user.errors[:password]).to include(I18n.t("password_validator.password_too_short"))
    end

    it "è valida con esattamente 12 caratteri conformi" do
      expect(validate_password("Abcdefgh12!_")).to be(true)
      expect(user.errors[:password]).to be_empty
    end

    it "è invalida se superiore a 256 caratteri" do
      long_password = "A1!a" + ("x" * 255)
      expect(validate_password(long_password)).to be(false)
      expect(user.errors[:password]).to include(I18n.t("password_validator.password_too_long"))
    end

    context "quando l'utente è admin e admin_password_strong è attivo" do
      let(:admin_user) { build(:user, :admin, organization: organization) }

      before do
        allow(Decidim.config).to receive(:admin_password_strong).and_return(true)
        allow(Decidim.config).to receive(:admin_password_min_length).and_return(15)
      end

      it "richiede la lunghezza minima prevista per gli amministratori (15 caratteri)" do
        expect(validate_password("Abcdefgh123!_a", admin_user)).to be(false) # 14 caratteri
        expect(admin_user.errors[:password]).to include(I18n.t("password_validator.password_too_short"))

        expect(validate_password("Abcdefgh1234!_a", admin_user)).to be(true) # 15 caratteri
      end
    end
  end

  describe "criteri di complessità caratteri" do
    before { I18n.locale = :it }

    it "è invalida se non contiene lettere maiuscole" do
      expect(validate_password("abcdefghil1_?a")).to be(false)
      expect(user.errors[:password]).to include("deve contenere almeno una lettera maiuscola")
    end

    it "è invalida se non contiene lettere minuscole" do
      expect(validate_password("ABCDEFGHIL1_?A")).to be(false)
      expect(user.errors[:password]).to include("deve contenere almeno una lettera minuscola")
    end

    it "è invalida se non contiene numeri" do
      expect(validate_password("ABCDEFGHIL__?a")).to be(false)
      expect(user.errors[:password]).to include("deve contenere almeno un numero")
    end

    it "è invalida se non contiene simboli speciali consentiti" do
      expect(validate_password("ABCDEFGHIL1234a")).to be(false)
      expect(user.errors[:password]).to include("deve contenere almeno un simbolo speciale (!@#$%^&*)")
    end

    it "è valida con diversi tipi di simboli speciali supportati" do
      symbols = %w(! @ # $ % ^ & * ( ) _ + { } [ ] : ; ' " / \\ ? > < . , -)
      symbols.each do |sym|
        pwd = "ABCDEFGHIL1#{sym}a"
        user.errors.clear
        expect(validator.validate_each(user, :password, pwd)).to be(true), "Failed for symbol: #{sym}"
      end
    end

    it "è invalida se ha meno di 5 caratteri unici" do
      # 12 caratteri ma solo 4 unici ('A', 'a', '1', '!')
      expect(validate_password("Aa1!Aa1!Aa1!")).to be(false)
      expect(user.errors[:password]).to include(I18n.t("password_validator.not_enough_unique_characters"))
    end

    it "segnala cumulativamente tutti gli errori di complessità mancanti" do
      # solo lettere minuscole corte e ripetute -> corto, pochi unici, no maiuscole, no numeri, no simboli
      validate_password("aaaa")
      expect(user.errors[:password]).to include(I18n.t("password_validator.password_too_short"))
      expect(user.errors[:password]).to include(I18n.t("password_validator.not_enough_unique_characters"))
      expect(user.errors[:password]).to include("deve contenere almeno una lettera maiuscola")
      expect(user.errors[:password]).to include("deve contenere almeno un numero")
      expect(user.errors[:password]).to include("deve contenere almeno un simbolo speciale (!@#$%^&*)")
    end
  end

  describe "controlli di sicurezza contestuali sull'utente e dominio" do
    it "è invalida se include il nome dell'utente" do
      expect(validate_password("Mario_ABCDEF1?a")).to be(false)
      expect(user.errors[:password]).to include(I18n.t("password_validator.name_included_in_password"))
    end

    it "è invalida se include il nickname dell'utente" do
      expect(validate_password("mariorossi_1?A")).to be(false)
      expect(user.errors[:password]).to include(I18n.t("password_validator.nickname_included_in_password"))
    end

    it "è invalida se include lo username dell'email o il dominio dell'email" do
      expect(validate_password("mario.rossi_1?A")).to be(false)
      expect(user.errors[:password]).to include(I18n.t("password_validator.email_included_in_password"))

      expect(validate_password("example_ABC1?a")).to be(false)
      expect(user.errors[:password]).to include(I18n.t("password_validator.email_included_in_password"))
    end

    it "è invalida se include il dominio o parti dell'host dell'organizzazione" do
      expect(validate_password("sardegna_ABC1?a")).to be(false)
      expect(user.errors[:password]).to include(I18n.t("password_validator.domain_included_in_password"))
    end

    it "è invalida se è una password comune o negata" do
      allow(Decidim::CommonPasswords.instance.passwords).to receive(:include?).and_return(true)
      expect(validate_password("ABCDEFGHIL1_?a")).to be(false)
      expect(user.errors[:password]).to include(I18n.t("password_validator.password_too_common"))
    end
  end

  describe "storico password per admin" do
    let(:admin_user) { create(:user, :admin, organization: organization, password: "OldAdminPassword1!_") }

    before do
      allow(Decidim.config).to receive(:admin_password_strong).and_return(true)
    end

    it "impedisce il riutilizzo della password precedente" do
      admin_user.password = "OldAdminPassword1!_"
      expect(validator.validate_each(admin_user, :password, "OldAdminPassword1!_")).to be(false)
      expect(admin_user.errors[:password]).to include(I18n.t("password_validator.password_repeated"))
    end
  end
end
