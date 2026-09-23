# frozen_string_literal: true

require "rails_helper"

RSpec.describe Decidim::ExtraUserFields::Admin::UpdateExtraUserFields, type: :command do
  let(:organization) { create(:organization, host: "partecipa.sardegna.it") }
  let(:current_user) { create(:user, :admin, organization: organization) }
  let(:params) do
    {
      enabled: true,
      country: true,
      postal_code: true,
      date_of_birth: true,
      gender: true,
      phone_number: true,
      phone_number_pattern: "\\A\\+39[0-9]{9,10}\\z",
      phone_number_placeholder: { "it" => "+39 123 456 7890" },
      location: false,
      underage: true,
      underage_limit: 18,
      personal_name: true,
      surname: true
    }
  end

  let(:form) do
    Decidim::ExtraUserFields::Admin::ExtraUserFieldsForm.from_params(params).with_context(
      current_organization: organization,
      current_user: current_user
    )
  end

  subject { described_class.new(form) }

  describe "esecuzione del comando" do
    context "quando il form è valido" do
      it "trasmette :ok e aggiorna extra_user_fields sull'organizzazione" do
        expect { subject.call }.to broadcast(:ok)

        organization.reload
        expect(organization.extra_user_fields["enabled"]).to be(true)
        expect(organization.extra_user_fields["personal_name"]).to eq({ "enabled" => true })
        expect(organization.extra_user_fields["surname"]).to eq({ "enabled" => true })
        expect(organization.extra_user_fields["country"]).to eq({ "enabled" => true })
        expect(organization.extra_user_fields["postal_code"]).to eq({ "enabled" => true })
        expect(organization.extra_user_fields["date_of_birth"]).to eq({ "enabled" => true })
        expect(organization.extra_user_fields["gender"]).to eq({ "enabled" => true })
        expect(organization.extra_user_fields["underage"]).to eq({ "enabled" => true })
        expect(organization.extra_user_fields["underage_limit"]).to eq(18)
        expect(organization.extra_user_fields["location"]).to eq({ "enabled" => false })
        expect(organization.extra_user_fields["phone_number"]["enabled"]).to be(true)
        expect(organization.extra_user_fields["phone_number"]["pattern"]).to eq("\\A\\+39[0-9]{9,10}\\z")
      end
    end

    context "quando il form non è valido" do
      before do
        allow(form).to receive(:invalid?).and_return(true)
      end

      it "trasmette :invalid e non aggiorna l'organizzazione" do
        expect { subject.call }.to broadcast(:invalid)
      end
    end
  end
end
