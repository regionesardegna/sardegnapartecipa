# Copyright (C) 2023 Sardegna IT
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>
#
# Modificata per prevedere il che siano passati in login e logout ulteriori pasametri
# funzionali a far eseguire correttamente il logout su AM Sardegna IT


Decidim::Spid::Utils.module_eval do
      def slo_saml(slo_params, options)
        logout_request = Decidim::Spid::SloRequest.new(slo_params,
                                                       options.merge(
                                                         name_identifier_value: session[:"#{session_prefix}uid"],
                                                         idp_name_qualifier: session[:"#{session_prefix}idp_name_qualifier"],
                                                         name_identifier_format: "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"
                                                       ))
        session[:"#{session_prefix}slo_id"] = logout_request.uuid
        logout_request.to_saml
      end

      def sso_request(saml_response, options)
	    Rails.logger.info "0 utils.sso_request ================================>"
		Rails.logger.info "0.1 utils.sso_request ================================> saml_response=#{saml_response}"
		Rails.logger.info "0.2 utils.sso_request ================================> session_prefix=#{session_prefix}"
		Rails.logger.info "0.3 utils.sso_request ================================> options=#{options}"
		Rails.logger.info "0.4 utils.sso_request ================================> session=#{session.inspect}"
		sso_params=session[:sardegnapartecipa_spid_sso_params]#undefined method dig for nil class
		Rails.logger.info "0.5 utils.sso_request ================================> sso_params=#{sso_params}"
        r = Decidim::Spid::SsoResponse.new(saml_response, session[:"#{session_prefix}sso_params"], options)
        Rails.logger.info "1 utils.sso_request ================================> r=#{r.inspect}"
		response = r.response
		Rails.logger.info "2 utils.sso_request ================================> response=#{response.inspect}"
        valid = r.valid?
		Rails.logger.info "3 utils.sso_request ================================> valid=#{valid}"
        if valid
          session[:"#{session_prefix}uid"] = response.attributes[options.uid_attribute] || response.name_id.try(:strip)
          session[:"#{session_prefix}index"] = r.session_index
          session[:"#{session_prefix}login_time"] = Time.now
          session[:"#{session_prefix}idp_name_qualifier"] = response.send(:name_id_node).attributes.dig("NameQualifier").to_s
          msg = 'decidim.spid.sso_request.success'
        else
          matches = nil
          Rails.logger.info "4 utils.sso_request ================================> errors= #{r.errors.inspect}"
		  if r.errors && r.errors.any?{ |a| matches = a.match(/The status code of the Response was not Success, was Responder => AuthnFailed -> ErrorCode nr(19|2[0-5])/) } && (error_code = matches.try(:[], 1)).present?
            msg = "decidim.spid.sso_request.failure_#{error_code}"
          else
            msg = 'decidim.spid.sso_request.failure'
          end
        end
        [valid, msg, response]
		rescue => e
		  Rails.logger.error e.message
          Rails.logger.error e.backtrace.join("\n")
      end
end