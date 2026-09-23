# frozen_string_literal: true

if Decidim::Spid.tenants.empty?
  Decidim::Spid.configure do |config|
    config.name = "spid"
    config.sp_entity_id = "http://localhost:3000/"
    config.metadata_attributes = {
      name: "name",
      surname: "familyName",
      fiscal_code: "fiscalNumber",
      gender: "gender",
      birthday: "dateOfBirth",
      birthplace: "placeOfBirth",
      company_name: "companyName",
      registered_office: "registeredOffice",
      iva_code: "ivaCode",
      id_card: "idCard",
      mobile_phone: "mobilePhone",
      email: "email",
      address: "address",
      digital_address: "digitalAddress"
    }
    config.export_exclude_attributes = [:name, :surname, :fiscal_code, :company_name, :registered_office, :email, :iva_code]
    config.sha = 256
    config.uid_attribute = :fiscalNumber
    config.relay_state = "/"
    config.organization = { it: { name: "Regione Autonoma della Sardegna", display: "Sardegna Partecipa", url: "https://sardegnapartecipa.regione.sardegna.it" } }
    config.contact_people_other = {
      public: true, ipa_code: "r_sardeg", vat_number: "00000000000",
      fiscal_code: "00000000000", given_name: "SPID Team", email: "spid@regione.sardegna.it",
      company: "Regione Autonoma della Sardegna", number: "+39070000000"
    }
    config.contact_people_billing = {}
    config.fields = [
      { name: "name", friendly_name: "Nome", is_required: true },
      { name: "familyName", friendly_name: "Cognome", is_required: true },
      { name: "fiscalNumber", friendly_name: "Codice Fiscale", is_required: true },
      { name: "email", friendly_name: "Email", is_required: true },
      { name: "spidCode", friendly_name: "Codice SPID", is_required: true }
    ]
  end
end
