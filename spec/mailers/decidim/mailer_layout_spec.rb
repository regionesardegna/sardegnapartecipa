# frozen_string_literal: true

require "rails_helper"

module Decidim
  describe "Layout delle email di Decidim", type: :mailer do
    let(:organization) { create(:organization, name: "Sardegna Partecipa", host: "partecipa.sardegna.it") }
    let(:user) { create(:user, organization: organization, email: "utente@example.org") }

    describe "Rendering dell'header e del footer" do
      let(:mail) do
        Decidim::DecidimDeviseMailer.confirmation_instructions(user, "TOKEN123", {})
      end

      it "renderizza l'header (.decidim-bar) con sfondo bianco" do
        expect(mail.body.encoded).to include("decidim-bar")
        expect(mail.body.encoded).to include("background-color: #ffffff")
      end

      it "renderizza il footer (.cityhall-bar) con sfondo bianco e colore del testo scuro" do
        expect(mail.body.encoded).to include("cityhall-bar")
        expect(mail.body.encoded).to include("border-top: 1px solid #e2e8f0")
        expect(mail.body.encoded).to include("color: #333333")
      end

      it "include il nome dell'organizzazione nel footer" do
        expect(mail.body.encoded).to include("Sardegna Partecipa")
      end
    end
  end
end
