# frozen_string_literal: true

require "rails_helper"

RSpec.describe Decidim::ExtraUserFields::Admin::ExtraUserFieldsForm, type: :form do
  let(:organization) do
    create(
      :organization,
      host: "partecipa.sardegna.it",
      extra_user_fields: {
        "enabled" => true,
        "country" => { "enabled" => true },
        "postal_code" => { "enabled" => true },
        "date_of_birth" => { "enabled" => false },
        "gender" => { "enabled" => true },
        "phone_number" => {
          "enabled" => true,
          "pattern" => "\\A\\+39[0-9]{9,10}\\z",
          "placeholder" => { "it" => "+39 123 456 7890" }
        },
        "location" => { "enabled" => false },
        "underage" => { "enabled" => true },
        "underage_limit" => 16,
        "personal_name" => { "enabled" => true },
        "surname" => { "enabled" => true }
      }
    )
  end

  subject { described_class.from_model(organization).with_context(current_organization: organization) }

  describe "#map_model" do
    it "mappa correttamente lo stato abilitato globale" do
      expect(subject.enabled).to be(true)
    end

    it "mappa i campi custom di Sardegna Partecipa (personal_name e surname)" do
      expect(subject.personal_name).to be(true)
      expect(subject.surname).to be(true)
    end

    it "mappa i campi standard della gemma" do
      expect(subject.country).to be(true)
      expect(subject.postal_code).to be(true)
      expect(subject.gender).to be(true)
      expect(subject.date_of_birth).to be(false)
      expect(subject.location).to be(false)
      expect(subject.underage).to be(true)
      expect(subject.underage_limit).to eq(16)
      expect(subject.phone_number).to be(true)
      expect(subject.phone_number_pattern).to eq("\\A\\+39[0-9]{9,10}\\z")
    end
  end
end
