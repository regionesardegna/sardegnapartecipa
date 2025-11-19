# frozen_string_literal: true

module Decidim
  class ExportJob < ApplicationJob
    queue_as :exports

    def perform(user, component, name, format, resource_id = nil)
      export_manifest = component.manifest.export_manifests.find do |manifest|
        manifest.name == name.to_sym
      end

      collection = export_manifest.collection.call(component, user, resource_id)
      serializer = export_manifest.serializer

      #Rails.logger.debug "================================> collection=#{collection.inspect}"
      #Rails.logger.debug "================================> serializer=#{serializer}"
      #Rails.logger.debug "================================> user=#{user.inspect} name=#{name}"
      
      Rails.logger.debug "================================> format=#{format}"
      organization = user.organization
	  
      #if format == "FormPDF" then
        #export_data = Decidim::Exporters.find_exporter(format).new(collection, serializer, organization).export
      #else
      export_data = Decidim::Exporters.find_exporter(format).new(collection, serializer).export
      #end
      ExportMailer.export(user, name, export_data).deliver_now
    end
  end
end
