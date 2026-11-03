require "spec_helper"

module Decidim
  describe CreateUser do
    let(:organization) { create(:organization) }
    let(:user_ip) { "203.0.113.195" }

    let(:form) do
      RegistrationForm.new(
        email: "user@example.org",
        name: "User Name",
        nickname: "username",
        password: "password123456_",
        password_confirmation: "password123456_",
        tos_agreement: "1"
      ).with_context(
        current_organization: organization,
        user_ip: user_ip
      )
    end

    subject { described_class.new(form) }

    it "registra l'utente e traccia l'IP nell'ActionLog" do
      expect { subject.call }.to change(Decidim::ActionLog, :count).by(1)

      log = Decidim::ActionLog.last
      created_user = Decidim::User.find_by(email: "user@example.org")

      expect(log.user).to eq(created_user)
      expect(log.action).to eq("create")
      expect(log.extra.dig("user", "ip")).to eq(user_ip)
    end
  end
end
