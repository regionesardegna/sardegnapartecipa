# frozen_string_literal: true

require "rails_helper"
require "zip"
require "cgi"

describe Decidim::Surveys::SurveyConfirmationMailer, type: :mailer do
  let(:logo) { double("Logo", attached?: false, url: "http://logo.it") }
  let(:organization) { instance_double("Decidim::Organization", id: 1, host: "localhost", logo: logo, name: "Sardegna", official_url: "http://sardegna.it", smtp_settings: {}) }
  let(:user) { instance_double("Decidim::User", organization: organization, name: "Test", email: "test@example.org", locale: "it") }
  let(:participatory_space) { instance_double("Decidim::ParticipatoryProcess", title: { "it" => "Space" }, slug: "space") }
  let(:component) { instance_double("Decidim::Component", participatory_space: participatory_space) }
  let(:survey) { instance_double("Decidim::Surveys::Survey", component: component) }
  let(:question) { instance_double("Decidim::Forms::Question", body: { "it" => "Domanda 1" }) }
  let(:questionnaire) { instance_double("Decidim::Forms::Questionnaire", title: { "it" => "Questionnaire" }, questionnaire_for: survey, questions: [question]) }
  let(:answers) { [instance_double("Decidim::Forms::Answer", body: "Risposta 1", question: question)] }

  let(:bcc_address) { "bcc@example.org" }

  before do
    # Stub I18n translation to avoid MissingTranslationData
    allow(I18n).to receive(:t).and_return("Traduzione")
    allow(I18n).to receive(:translate).and_return("Traduzione")

    allow(ENV).to receive(:[]).with('SURVEYS_NOTIFICATION_BCC_ADDRESS').and_return(bcc_address)
    
    # Mocking FileZipper per creare uno zip reale
    stub_const("FileZipper", Class.new do
      def initialize(filename, data)
        @filename = filename
        @data = data
      end
      
      def zip
        zip_buffer = Zip::OutputStream.write_buffer do |zio|
          zio.put_next_entry(@filename)
          zio.write @data
        end
        zip_buffer.string
      end
    end)

    # Mocking Exporter
    export = double("Export", filename: "test.pdf", read: "%PDF-1.4\n1 0 obj\n<</Title (Questionario)>>\nendobj\n/Content (Domanda 1 Risposta 1)\n%%EOF")
    allow(export).to receive(:filename).with(any_args).and_return("test.pdf")
    export_data = instance_double("Decidim::Exporters::FormPDF", export: export)
    allow(Decidim::Exporters::FormPDF).to receive(:new).and_return(export_data)
  end

  describe "confirmation" do
    let(:mail) { described_class.confirmation(user, questionnaire, answers) }

    it "invia l'email all'utente con l'indirizzo BCC configurato" do
      expect(mail.to).to eq([user.email])
      expect(mail.bcc).to eq([bcc_address])
      expect(mail.subject).to be_present
    end

    it "contiene l'allegato ZIP col PDF corretto" do
      attachment = mail.attachments.find { |a| a.filename.end_with?(".zip") }
      expect(attachment).not_to be_nil
      
      Zip::InputStream.open(StringIO.new(attachment.decoded)) do |io|
        entry = io.get_next_entry
        expect(entry.name).to eq("test.pdf")
        pdf_content = io.read
        expect(pdf_content).to start_with("%PDF-")
        expect(pdf_content).to include("Questionario")
        expect(pdf_content).to include("Domanda 1")
        expect(pdf_content).to include("Risposta 1")
      end
    end

    context "con le traduzioni italiane reali" do
      before do
        allow(I18n).to receive(:t).and_call_original
        allow(I18n).to receive(:translate).and_call_original
        allow_any_instance_of(described_class).to receive(:add_file_with_answers)
      end

      it "renderizza il saluto e il testo tradotti senza allegato" do
        I18n.with_locale(:it) do
          messaggio = mail
          parte_html = messaggio.html_part || (messaggio if messaggio.mime_type == "text/html")

          expect(messaggio.subject).to eq("Risposte al questionario Questionnaire")
          expect(messaggio.attachments).to be_empty
          expect(parte_html).not_to be_nil

          html = CGI.unescapeHTML(parte_html.body.decoded)
          expect(html).to include("Gentile Test,")
          expect(html).to include("in allegato, all'interno dell'archivio .ZIP, il file .PDF contenente le tue risposte alle domande del questionario Questionnaire / Space")
        end
      end
    end
  end
end
