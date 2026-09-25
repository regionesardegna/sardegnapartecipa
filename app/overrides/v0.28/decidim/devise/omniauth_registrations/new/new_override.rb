# Copyright (C) 2026 Formez PA
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Viene forzato in fase di registrazione l'utente a conservare l'email proveniente da SPID, nel caso di email presente o presente tra i parametri (caso di validazione errata che va gestito)
# Aggiunto campo per la gestione omniauth in caso di errori di validazioni

Deface::Override.new(
  virtual_path: "decidim/devise/omniauth_registrations/new",
  name: "disable-email-field-when-not-available",
  replace: "erb:contains('f.email_field :email')"
) do
  '
<%
# 1. Recuperiamo l\'hash omniauth se presente in sessione
omniauth_data = session["decidim.omniauth_data"] || {}
extra_info = omniauth_data["extra"] || omniauth_data[:extra] || {}
raw_info = extra_info["raw_info"] || extra_info[:raw_info] || {}

# 2. Estraiamo l\'issuer o l\'identity provider se tracciato
idp_issuer = raw_info["issuer"] || raw_info[:issuer] || omniauth_data.dig("info", "identity_provider")

# 3. Verifichiamo se si tratta esplicitamente di CIE
is_cie = idp_issuer.to_s.downcase.include?("interno.gov.it") || idp_issuer.to_s.downcase.include?("cie")

# 4. Estraiamo l\'email (da f.object o dalla sessione)
form_email = f.object.try(:email).presence || omniauth_data.dig("info", "email").presence

# 5. L\'email deve essere bloccata SOLO se l\'autenticazione NON è CIE ed è presente un\'email certificata
is_email_readonly = !is_cie && form_email.present?
%>

<% if is_email_readonly %>
  <%= f.email_field :email,
                    value: form_email,
                    readonly: true,
                    onfocus: "this.blur();",
                    style: "background-color: #f3f4f6; cursor: not-allowed;" %>
<% else %>
  <%= f.email_field :email, value: form_email %>
<% end %>

<%= f.hidden_field :raw_data %>
'
end

