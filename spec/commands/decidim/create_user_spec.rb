# frozen_string_literal: true

require "rails_helper"

module Decidim
  describe CreateRegistration do
    describe "call" do
      let(:organization) { create(:organization) }

      let(:name) { "User Name" }
      let(:email) { "user@example.org" }
      let(:password) { 'Test12345!@#' }
      let(:tos_agreement) { "1" }

      let(:current_locale) { "it" }

      let(:form_params) do
        {
          "user" => {
            "name" => name,
            "email" => email,
            "password" => password,
            "tos_agreement" => tos_agreement
          }
        }
      end

      let(:form) do
        RegistrationForm.from_params(
          form_params,
          current_locale:
        ).with_context(
          current_organization: organization
        )
      end

      let(:command) { described_class.new(form) }

      context "quando il form non è valido" do
        before do
          allow(form).to receive(:invalid?).and_return(true)
        end

        it "broadcasta :invalid" do
          expect { command.call }.to broadcast(:invalid)
        end

        it "non crea un utente" do
          expect {
            command.call
          }.not_to change(Decidim::User, :count)
        end
      end

      context "quando il form è valido" do
        it "broadcasta :ok" do
          expect { command.call }.to broadcast(:ok)
        end

        it "crea un nuovo utente" do
          expect { command.call }.to change(Decidim::User, :count).by(1)

          created_user = Decidim::User.find_by(email: email)
          expect(created_user).to be_present
          expect(created_user.name).to eq(name)
          expect(created_user.organization).to eq(organization)
        end
      end
    end
  end
end
