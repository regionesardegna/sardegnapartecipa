# frozen_string_literal: true

require "wicked_pdf"

module Decidim
  module Exporters
    # Inherits from abstract PDF exporter. This class is used to set
    # the parameters used to create a PDF when exporting Survey Answers.
    #
    class FormPDF < PDF
      # i18n-tasks-use t('decidim.admin.exports.formats.FormPDF')
      def initialize(organization, answers, serializer)
        super(answers, serializer)
        @organization=organization
		Rails.logger.info "===================================> FormPDF.initialize oraganization=#{@organization.host}"
      end	
      
	  def controller
        @controller ||= FormPDFControllerHelper.new
      end

      def template
        "decidim/forms/admin/questionnaires/answers/export/pdf.html.erb"
      end

      def layout
        "decidim/forms/admin/questionnaires/questionnaire_answers.html.erb"
      end

      def locals
        {
          organization: @organization,
		  questionnaire: collection.first.first.questionnaire,
          collection: collection.map { |answer| Decidim::Forms::Admin::QuestionnaireParticipantPresenter.new(participant: answer.first) }
        }
      end
    end
  end
end