# frozen_string_literal: true

# Copyright (C) 2025 Sardegna IT
#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Modificato per gestire la notifica utente per le surveys, eliminata la organization che generava un errore su 0.27.10

require "wicked_pdf"

module Decidim
  module Exporters
    # Inherits from abstract PDF exporter. This class is used to set
    # the parameters used to create a PDF when exporting Survey Answers.
    #
    class FormPDF < PDF
      # i18n-tasks-use t('decidim.admin.exports.formats.FormPDF')
      def initialize(answers, serializer)
        super(answers, serializer)
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
          questionnaire: collection.first.first.questionnaire,
          collection: collection.map { |answer| Decidim::Forms::Admin::QuestionnaireParticipantPresenter.new(participant: answer.first) }
        }
      end
    end
  end
end
