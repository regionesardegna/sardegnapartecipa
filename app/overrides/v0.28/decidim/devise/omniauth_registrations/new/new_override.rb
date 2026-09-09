# Copyright (C) 2026 Regione Sardegna
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Riabilitata la possibiltà di cambiare email
# 
Deface::Override.new(virtual_path: "decidim/devise/omniauth_registrations/new",
                     name: "re-enable-email-with-spid2",
                     replace: "erb:contains('f.email_field :email')") do
'

<% param_email = params["user"]["email"].present? if params.present? && params["user"].present?%>
<%= f.email_field :email, autocomplete: "email", placeholder: t("placeholder_email", scope: "decidim.devise.shared") %>

'
end