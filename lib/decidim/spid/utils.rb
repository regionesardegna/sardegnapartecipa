# Copyright (C) 2024 Sardegna IT
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# frozen_string_literal: true

# Modificata per prevedere che siano passati in login e logout ulteriori pasametri funzionali a far eseguire correttamente il logout su AM Sardegna IT
# modificato funzionamento dei cookies in funzione delle modifiche a 0.26 sui cookies vedi release notes 

module Decidim
  module Spid
    module Utils

      cattr_accessor :current_name, default: ''

      def metadata_xml(overrides = {})
        metadata = Decidim::Spid::Metadata.new
        metadata.to_xml(Decidim::Spid::Settings::Metadata.new(overrides))
		rescue => e
		  Rails.logger.error "Utils.metadata_xml ================================> " + e.message
          Rails.logger.error "Utils.metadata_xml ================================> " + e.backtrace.join("\n")
      end

      def sso_saml(sso_params, options)
        request = Decidim::Spid::SsoRequest.new(sso_params, options)
        session[:"tenant-spid-name"] = options["name"]
        
		sso_params.each {|k,v|
			session[k] = v
		}
		session[:issue_instant] = request.issue_instant
		session[:uuid] = request.uuid
        request.to_saml
		rescue => e
		  Rails.logger.error "Utils.sso_saml ================================> " + e.message
          Rails.logger.error "Utils.sso_saml ================================> " + e.backtrace.join("\n")
      end

      def slo_saml(slo_params, options)
        logout_request = Decidim::Spid::SloRequest.new(slo_params,
                                                       options.merge(
                                                         #name_identifier_value: session[:"#{session_prefix}uid"],
                                                         #idp_name_qualifier: session[:"#{session_prefix}idp_name_qualifier"],
														 name_identifier_value: session[:uid],
                                                         idp_name_qualifier: session[:idp_name_qualifier],
                                                         name_identifier_format: "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"
                                                       ))
		session[:slo_id] = logout_request.uuid
        logout_request.to_saml
		rescue => e
		  Rails.logger.error "Utils.slo_saml ================================> " + e.message
 	      Rails.logger.error "Utils.slo_saml ================================> " + e.backtrace.join("\n")
      end

      def sso_request(saml_response, options)
 	    # modificato rispetto alla 0.25.2 modalità di passaggio dei parametri sso estratti da cookie
		curr_sso_params = Hash.new
		curr_sso_params[:"#{session_prefix}sso_params"] = Hash.new
		curr_sso_params[:"#{session_prefix}sso_params"]["sso"] = session[:sso]
		curr_sso_params[:"#{session_prefix}sso_params"]["spid_level"] = session[:spid_level]
		curr_sso_params[:"#{session_prefix}sso_params"]["host"] = session[:host]
		curr_sso_params[:"#{session_prefix}sso_params"]["relay_state"] = session[:relay_state]
		curr_sso_params[:"#{session_prefix}sso_params"]["issue_instant"] = session[:issue_instant]
		curr_sso_params[:"#{session_prefix}sso_params"]["uuid"] = session[:uuid]
		r = Decidim::Spid::SsoResponse.new(saml_response, curr_sso_params[:"#{session_prefix}sso_params"], options)
		response = r.response
        valid = r.valid?
		Rails.logger.info "Utils.sso_request ================================> valid=#{valid}"
        if valid
          session[:uid] = response.attributes[options.uid_attribute] || response.name_id.try(:strip)
		  session[:index] = r.session_index
		  session[:login_time] = Time.now
		  session[:idp_name_qualifier] = response.send(:name_id_node).attributes.dig("NameQualifier").to_s
		  msg = 'decidim.spid.sso_request.success'
        else
          matches = nil
		  if r.errors && r.errors.any?{ |a| matches = a.match(/The status code of the Response was not Success, was Responder => AuthnFailed -> ErrorCode nr(19|2[0-5])/) } && (error_code = matches.try(:[], 1)).present?
            msg = "decidim.spid.sso_request.failure_#{error_code}"
          else
            msg = 'decidim.spid.sso_request.failure'
          end
        end
        [valid, msg, response]
		rescue => e
		  Rails.logger.error "Utils.sso_request ================================> " + e.message
          Rails.logger.error "Utils.sso_request ================================> " + e.backtrace.join("\n")
      end
	
	  def slo_request(saml_response, options)
	    # modificato rispetto alla 0.25.2 modalità di passaggio dei parametri sso estratti da cookie
		curr_sso_params = Hash.new
		curr_sso_params[:"#{session_prefix}sso_params"] = Hash.new
		curr_sso_params[:"#{session_prefix}sso_params"]["sso"] = session[:sso]
		curr_sso_params[:"#{session_prefix}sso_params"]["spid_level"] = session[:spid_level]
		curr_sso_params[:"#{session_prefix}sso_params"]["host"] = session[:host]
		curr_sso_params[:"#{session_prefix}sso_params"]["relay_state"] = session[:relay_state]
		curr_sso_params[:"#{session_prefix}sso_params"]["issue_instant"] = session[:issue_instant]
		curr_sso_params[:"#{session_prefix}sso_params"]["uuid"] = session[:uuid]
		
		#Rails.logger.info "Utils.slo_request ================================> session[:name_id] = #{session[:name_id]}"
		Rails.logger.info "Utils.slo_request ================================> saml_response = #{saml_response.inspect}"
		
        response = Decidim::Spid::SloResponse.new(saml_response, curr_sso_params[:"#{session_prefix}sso_params"].merge(slo_id: session[:slo_id]), options)
        valid = response.valid?
        if valid
		  session.delete(:index)
		  session.delete(:slo_id)
		  session.delete(:relay_state)
		  session.delete(:login_time)

          msg = 'decidim.spid.slo_request.success'
        else
          msg = 'decidim.spid.slo_request.failure'
        end
        [valid, msg]
		rescue => e
		  Rails.logger.error "Utils.slo_request ================================> " + e.message
          Rails.logger.error "Utils.slo_request ================================> " + e.backtrace.join("\n")
      end

      def slo_params
        sso_params = {}
        #sso_params[:sso] = { idp: session[:"#{session_prefix}sso_params"].dig("sso", "idp") }
        #sso_params[:spid_level] = session[:"#{session_prefix}sso_params"]["spid_level"]
        #sso_params[:session_index] = session[:"#{session_prefix}index"]
        #sso_params[:relay_state] = Base64.strict_decode64(session[:"#{session_prefix}sso_params"]["relay_state"])
        #Rails.logger.info "Utils.slo_params ================================> session[:name_id] = #{session[:name_id]}"
		sso_params[:sso] = { idp: session[:sso].dig("idp") }
		sso_params[:spid_level] = session[:spid_level]
		sso_params[:session_index] = session[:index]
		sso_params[:relay_state] = Base64.strict_decode64(session["relay_state"])
		Rails.logger.info "Utils.slo_request ================================> session[:name_id] = #{session[:name_id]}"
		
		
		sso_params
		rescue => e
		  Rails.logger.error "Utils.slo_params ================================> " + e.message
          Rails.logger.error "Utils.slo_params ================================> " + e.backtrace.join("\n")
      end

      def session_prefix
        options["name"] + '_spid_'
      end
	  
	end
  end
end