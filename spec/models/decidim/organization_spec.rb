# frozen_string_literal: true

require "rails_helper"

RSpec.describe Decidim::Organization, type: :model do
  let(:extra_user_fields) { { "enabled" => false } }
  let(:organization) { build(:organization, extra_user_fields: extra_user_fields) }

  describe "metodi di configurazione per extra_user_fields (OrganizationOverrides)" do
    describe "#extra_user_fields_enabled?" do
      it "restituisce false/nil quando extra_user_fields['enabled'] è false" do
        organization.extra_user_fields = {
          "enabled" => false,
          "personal_name" => { "enabled" => true },
          "surname" => { "enabled" => true }
        }
        expect(organization.extra_user_fields_enabled?).to be_falsey
      end

      it "restituisce false/nil quando 'enabled' è true ma nessun campo singolo è abilitato" do
        organization.extra_user_fields = {
          "enabled" => true,
          "underage_limit" => 18
        }
        expect(organization.extra_user_fields_enabled?).to be_falsey
      end

      it "restituisce true quando 'enabled' è true e almeno un campo è abilitato" do
        organization.extra_user_fields = {
          "enabled" => true,
          "personal_name" => { "enabled" => true }
        }
        expect(organization.extra_user_fields_enabled?).to be_truthy
      end
    end

    describe "#at_least_one_extra_field?" do
      it "restituisce false quando non ci sono campi abilitati" do
        organization.extra_user_fields = {
          "enabled" => true,
          "country" => { "enabled" => false },
          "personal_name" => { "enabled" => false }
        }
        expect(organization.at_least_one_extra_field?).to be(false)
      end

      it "restituisce true se almeno un campo tra quelli disponibili è abilitato" do
        organization.extra_user_fields = {
          "enabled" => true,
          "personal_name" => { "enabled" => true },
          "surname" => { "enabled" => false }
        }
        expect(organization.at_least_one_extra_field?).to be(true)
      end

      it "ignora le chiavi 'enabled' e 'underage_limit'" do
        organization.extra_user_fields = {
          "enabled" => true,
          "underage_limit" => 18
        }
        expect(organization.at_least_one_extra_field?).to be(false)
      end
    end

    describe "#activated_extra_field?" do
      before do
        organization.extra_user_fields = {
          "enabled" => true,
          "personal_name" => { "enabled" => true },
          "surname" => { "enabled" => true },
          "country" => { "enabled" => false }
        }
      end

      it "restituisce true per un campo abilitato" do
        expect(organization.activated_extra_field?(:personal_name)).to be(true)
        expect(organization.activated_extra_field?(:surname)).to be(true)
      end

      it "restituisce false per un campo disabilitato o non presente" do
        expect(organization.activated_extra_field?(:country)).to be(false)
        expect(organization.activated_extra_field?(:gender)).to be(false)
      end
    end

    describe "#extra_user_field_configuration" do
      before do
        organization.extra_user_fields = {
          "enabled" => true,
          "phone_number" => {
            "enabled" => true,
            "pattern" => "\\A\\+39[0-9]{9,10}\\z",
            "placeholder" => "+39 123 456 7890"
          },
          "country" => { "enabled" => false }
        }
      end

      it "restituisce la configurazione del campo senza la chiave 'enabled'" do
        config = organization.extra_user_field_configuration(:phone_number)
        expect(config).to eq({
          "pattern" => "\\A\\+39[0-9]{9,10}\\z",
          "placeholder" => "+39 123 456 7890"
        })
      end

      it "restituisce un hash vuoto per i campi non abilitati" do
        expect(organization.extra_user_field_configuration(:country)).to eq({})
        expect(organization.extra_user_field_configuration(:date_of_birth)).to eq({})
      end
    end

    describe "#age_limit?" do
      it "restituisce il limite di età convertito in intero" do
        organization.extra_user_fields = { "underage_limit" => 16 }
        expect(organization.age_limit?).to eq(16)
      end

      it "restituisce 0 se non impostato" do
        organization.extra_user_fields = {}
        expect(organization.age_limit?).to eq(0)
      end
    end
  end
end
