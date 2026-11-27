# frozen_string_literal: true

require "rails_helper"
require "zlib"
require "base64"

RSpec.describe "Logging SAML e OmniAuth (omniauth_logger.rb)", type: :unit do
  let(:log_output) { StringIO.new }
  let(:test_logger) do
    ActiveSupport::Logger.new(log_output).tap do |logger|
      logger.level = Logger::DEBUG
      logger.formatter = ::Logger::Formatter.new
    end
  end

  before do
    # Reindirizziamo l'output di SAML_LOGGER su uno StringIO per poter verificare i log prodotti nei test
    stub_const("SAML_LOGGER", test_logger)
  end

  describe "Configurazione del logger" do
    it "configura SAML_LOGGER come istanza di ActiveSupport::Logger" do
      expect(SAML_LOGGER).to be_a(ActiveSupport::Logger)
    end

    it "collega OmniAuth.config.logger a SAML_LOGGER" do
      expect(OmniAuth.config.logger).to be_present
    end

    it "collega OneLogin::RubySaml::Logging.logger a SAML_LOGGER" do
      expect(OneLogin::RubySaml::Logging.logger).to be_present
    end
  end

  describe "SamlTrafficLogger (Rack Middleware)" do
    let(:app) { ->(env) { [200, { "Content-Type" => "text/plain" }, ["OK"]] } }
    let(:middleware) { SamlTrafficLogger.new(app) }

    let(:authn_request_xml) do
      <<~XML.strip
        <samlp:AuthnRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" ID="_authn_req_123" Version="2.0" IssueInstant="2026-11-13T10:00:00Z">
          <saml:Issuer xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">https://sp.example.org</saml:Issuer>
        </samlp:AuthnRequest>
      XML
    end

    let(:saml_response_xml) do
      <<~XML.strip
        <samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" ID="_resp_456" Version="2.0">
          <saml:Assertion xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">
            <saml:Subject>
              <saml:NameID>TINIT-RSSMRA80A01H501Z</saml:NameID>
            </saml:Subject>
          </saml:Assertion>
        </samlp:Response>
      XML
    end

    describe "Richiesta SAML AuthNRequest in uscita (HTTP-Redirect)" do
      let(:deflated_saml_request) do
        deflater = Zlib::Deflate.new(Zlib::DEFAULT_COMPRESSION, -Zlib::MAX_WBITS)
        data = deflater.deflate(authn_request_xml, Zlib::FINISH)
        deflater.close
        Base64.strict_encode64(data)
      end

      let(:redirect_location) do
        "https://idp.example.org/samlsso?SAMLRequest=#{Rack::Utils.escape(deflated_saml_request)}&RelayState=%2F"
      end

      let(:app) do
        ->(_env) { [302, { "Location" => redirect_location, "Content-Type" => "text/html" }, ["Redirecting..."]] }
      end

      it "cattura e registra le informazioni di redirect e l'XML scompattato della SAMLRequest" do
        env = Rack::MockRequest.env_for("/users/auth/spid", "REMOTE_ADDR" => "10.0.0.1")

        status, headers, _body = middleware.call(env)

        expect(status).to eq(302)
        expect(headers["Location"]).to eq(redirect_location)

        logs = log_output.string
        expect(logs).to include("[OUTGOING SAMLRequest HTTP-Redirect] Verso: idp.example.org | IP: 10.0.0.1")
        expect(logs).to include("[OUTGOING SP AUTH REQUEST XML]")
        expect(logs).to include('<samlp:AuthnRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" ID="_authn_req_123"')
      end

      context "quando la SAMLRequest nel redirect non è valida o è corrotta" do
        let(:redirect_location) do
          "https://idp.example.org/samlsso?SAMLRequest=CORRUPTED_BASE64_DATA"
        end

        it "traccia l'errore di decodifica nel log senza interrompere la risposta" do
          env = Rack::MockRequest.env_for("/users/auth/spid", "REMOTE_ADDR" => "10.0.0.1")

          status, = middleware.call(env)

          expect(status).to eq(302)
          logs = log_output.string
          expect(logs).to include("[SAML LOGGER ERROR] Impossibile decodificare SAMLRequest Redirect")
        end
      end
    end

    describe "Richiesta SAML AuthNRequest in uscita (HTTP-POST)" do
      let(:base64_saml_request) { Base64.strict_encode64(authn_request_xml) }
      let(:form_html) do
        <<~HTML
          <html>
            <body>
              <form action="https://idp.example.org/samlsso" method="post">
                <input type="hidden" name="SAMLRequest" value="#{base64_saml_request}" />
                <input type="hidden" name="RelayState" value="/" />
                <input type="submit" value="Invia" />
              </form>
            </body>
          </html>
        HTML
      end

      let(:app) do
        ->(_env) { [200, { "Content-Type" => "text/html; charset=utf-8" }, [form_html]] }
      end

      it "cattura e registra le informazioni della form POST e l'XML decodificato" do
        env = Rack::MockRequest.env_for("/users/auth/spid", "REMOTE_ADDR" => "10.0.0.2")

        status, _headers, body = middleware.call(env)

        expect(status).to eq(200)
        expect(body).to eq([form_html])

        logs = log_output.string
        expect(logs).to include("[OUTGOING SAMLRequest HTTP-POST] Path: /users/auth/spid | IP: 10.0.0.2")
        expect(logs).to include("[OUTGOING SP AUTH REQUEST XML]")
        expect(logs).to include('<samlp:AuthnRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" ID="_authn_req_123"')
      end

      context "quando l'attributo value precede l'attributo name nel form HTML" do
        let(:form_html) do
          %(<html><body><form><input type="hidden" value="#{base64_saml_request}" name="SAMLRequest" /></form></body></html>)
        end

        it "individua comunque la SAMLRequest e ne registra l'XML" do
          env = Rack::MockRequest.env_for("/users/auth/spid", "REMOTE_ADDR" => "10.0.0.3")

          middleware.call(env)

          logs = log_output.string
          expect(logs).to include("[OUTGOING SAMLRequest HTTP-POST] Path: /users/auth/spid | IP: 10.0.0.3")
          expect(logs).to include("[OUTGOING SP AUTH REQUEST XML]")
        end
      end
    end

    describe "Ricezione SAMLResponse in ingresso (Callback dall'IdP)" do
      let(:base64_saml_response) { Base64.strict_encode64(saml_response_xml) }

      it "cattura la risposta SAML in ingresso, logga l'XML e riavvolge il corpo della richiesta" do
        input_body = "SAMLResponse=#{Rack::Utils.escape(base64_saml_response)}&RelayState=%2F"
        env = Rack::MockRequest.env_for(
          "/users/auth/spid/callback",
          method: "POST",
          input: input_body,
          "CONTENT_TYPE" => "application/x-www-form-urlencoded",
          "REMOTE_ADDR" => "192.168.1.100"
        )

        status, _headers, body = middleware.call(env)

        expect(status).to eq(200)
        expect(body).to eq(["OK"])

        # Verifica che il body possa essere riletto dai middleware o controller successivi
        expect(env["rack.input"].read).to eq(input_body)

        logs = log_output.string
        expect(logs).to include("[INCOMING SAMLResponse] Path: /users/auth/spid/callback | IP: 192.168.1.100")
        expect(logs).to include("[INCOMING IDP SAML RESPONSE XML]")
        expect(logs).to include('<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" ID="_resp_456"')
        expect(logs).to include("<saml:NameID>TINIT-RSSMRA80A01H501Z</saml:NameID>")
      end

      it "funziona correttamente anche con parametri SAML su percorsi che contengono /spid o /saml" do
        env = Rack::MockRequest.env_for(
          "/spid/samlsso",
          method: "POST",
          params: { "SAMLResponse" => base64_saml_response },
          "REMOTE_ADDR" => "192.168.1.101"
        )

        middleware.call(env)

        logs = log_output.string
        expect(logs).to include("[INCOMING SAMLResponse] Path: /spid/samlsso | IP: 192.168.1.101")
      end
    end

    describe "Richieste non di autenticazione" do
      it "ignora percorsi generici senza loggare eventi SAML" do
        env = Rack::MockRequest.env_for("/processes", "REMOTE_ADDR" => "127.0.0.1")

        status, _headers, body = middleware.call(env)

        expect(status).to eq(200)
        expect(body).to eq(["OK"])
        expect(log_output.string).to be_empty
      end
    end
  end

  describe "Gestione fallimenti e validazione SAML (OmniAuth.config.on_failure)" do
    let(:on_failure_handler) { OmniAuth.config.on_failure }

    context "quando si verifica un errore di validazione OneLogin::RubySaml::ValidationError" do
      let(:validation_error) do
        OneLogin::RubySaml::ValidationError.new("Firma della risposta SAML non valida o certificato scaduto").tap do |err|
          err.set_backtrace([
            "/app/lib/ruby_saml/response.rb:100:in `validate_signature'",
            "/app/lib/ruby_saml/response.rb:50:in `validate'"
          ])
        end
      end

      let(:env) do
        Rack::MockRequest.env_for("/users/auth/spid/callback").merge(
          "omniauth.error" => validation_error,
          "omniauth.error.type" => :invalid_response
        )
      end

      it "traccia l'errore di validazione SAML con classe, messaggio e backtrace su SAML_LOGGER e inoltra al gestore dei fallimenti" do
        response = on_failure_handler.call(env)

        expect(response[0]).to eq(302)

        logs = log_output.string
        expect(logs).to include("[OMNIAUTH / SAML FAILURE] Type: :invalid_response | Class: OneLogin::RubySaml::ValidationError")
        expect(logs).to include("Messaggio: Firma della risposta SAML non valida o certificato scaduto")
        expect(logs).to include("Backtrace:\n/app/lib/ruby_saml/response.rb:100:in `validate_signature'")
      end
    end

    context "quando si verifica un errore generico OmniAuth" do
      let(:generic_error) { StandardError.new("Timeout durante la connessione con l'Identity Provider") }
      let(:env) do
        Rack::MockRequest.env_for("/users/auth/spid/callback").merge(
          "omniauth.error" => generic_error,
          "omniauth.error.type" => :timeout
        )
      end

      it "traccia l'errore generico con il tipo e la classe dell'eccezione" do
        allow(OmniAuth::FailureEndpoint).to receive(:call).and_return([302, { "Location" => "/users/auth/failure" }, ["Redirecting..."]])

        on_failure_handler.call(env)

        logs = log_output.string
        expect(logs).to include("[OMNIAUTH / SAML FAILURE] Type: :timeout | Class: StandardError")
        expect(logs).to include("Messaggio: Timeout durante la connessione con l'Identity Provider")
      end
    end
  end
end
