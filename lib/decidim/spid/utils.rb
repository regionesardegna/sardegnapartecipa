# Copyright (C) 2023 Sardegna IT
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>
#
# Modificata per prevedere che siano passati in login e logout ulteriori pasametri funzionali a far eseguire correttamente il logout su AM Sardegna IT

module Decidim
  module Spid
    module Utils

      cattr_accessor :current_name, default: ''

      def metadata_xml(overrides = {})
        metadata = Decidim::Spid::Metadata.new
        metadata.to_xml(Decidim::Spid::Settings::Metadata.new(overrides))
      end

      def sso_saml(sso_params, options)
        request = Decidim::Spid::SsoRequest.new(sso_params, options)
        session[:"tenant-spid-name"] = options["name"]
		#Rails.logger.info "0 utils.sso_saml ================================> sso_params=#{session[:"tenant-spid-name"]}"
		
		#sso_params=session[:"sardegnapartecipa_spid_sso_params"] #undefined method dig for nil class
		Rails.logger.info "1 utils.sso_saml ================================> sso_params=#{sso_params}"
		
        session[:"#{session_prefix}sso_params"] = sso_params.merge(
          issue_instant: request.issue_instant,
          uuid: request.uuid)
        request.to_saml
      end

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
		#Rails.logger.info "0.1 utils.sso_request ================================> saml_response=#{saml_response}"
		#Rails.logger.info "0.2 utils.sso_request ================================> session_prefix=#{session_prefix}"
		Rails.logger.info "0.3 utils.sso_request ================================> options=#{options}"
		#Rails.logger.info "0.4 utils.sso_request ================================> session=#{session.inspect}"
		sso_params=session[:"sardegnapartecipa_spid_sso_params"]#undefined method dig for nil class
		#Rails.logger.info "0.5 utils.sso_request ================================> sso_params=#{sso_params}"
        r = Decidim::Spid::SsoResponse.new(saml_response, session[:"#{session_prefix}sso_params"], options)
        #Rails.logger.info "1 utils.sso_request ================================> r=#{r.inspect}"
		response = r.response
		#Rails.logger.info "2 utils.sso_request ================================> response=#{response.inspect}"
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
          #Rails.logger.info "4 utils.sso_request ================================> errors= #{r.errors.inspect}"
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
	
	  def slo_request(saml_response, options)
        response = Decidim::Spid::SloResponse.new(saml_response, session[:"#{session_prefix}sso_params"].merge(slo_id: session[:"#{session_prefix}slo_id"]), options)
        valid = response.valid?
        if valid
          session.delete(:"#{session_prefix}sso_params")
          session.delete(:"#{session_prefix}index")
          session.delete(:"#{session_prefix}slo_id")
          session.delete(:"#{session_prefix}relay_state")
          session.delete(:"#{session_prefix}login_time")
          msg = 'decidim.spid.slo_request.success'
        else
          msg = 'decidim.spid.slo_request.failure'
        end
        [valid, msg]
      end

      def slo_params
        sso_params = {}
        sso_params[:sso] = { idp: session[:"#{session_prefix}sso_params"].dig("sso", "idp") }
        sso_params[:spid_level] = session[:"#{session_prefix}sso_params"]["spid_level"]
        sso_params[:session_index] = session[:"#{session_prefix}index"]
        sso_params[:relay_state] = Base64.strict_decode64(session[:"#{session_prefix}sso_params"]["relay_state"])
        sso_params
      end

      def session_prefix
        options["name"] + '_spid_'
      end

	end
  end
end