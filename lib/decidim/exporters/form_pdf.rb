# frozen_string_literal: true

# Copyright (C) 2025 Sardegna IT
#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Modificato per gestire la notifica utente per le surveys

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
        # In Decidim 0.28, 'collection' contiene direttamente gli oggetti Answer.
        # Estraiamo in sicurezza il primo oggetto per risalire al questionario comune.
        first_answer = collection.respond_to?(:first) ? collection.first : nil
        
        # Gestiamo il caso in cui la collection sia un array piana di risposte
        resolved_questionnaire = if first_answer.respond_to?(:questionnaire)
                                   first_answer.questionnaire
                                 elsif first_answer.is_a?(Array)
                                   first_answer.first&.respond_to?(:questionnaire) ? first_answer.first.questionnaire : nil
                                 else
                                   nil
                                 end

        {
          organization: @organization,
          questionnaire: resolved_questionnaire,
          # Mappiamo ogni singola risposta direttamente nel presenter ministeriale della 0.28
          collection: collection.map { |answer| 
            # Se per qualche motivo l'elemento è ancora un array prendiamo il primo, altrimenti l'oggetto stesso
            actual_answer = answer.is_a?(Array) ? answer.first : answer
            Decidim::Forms::Admin::QuestionnaireParticipantPresenter.new(participant: actual_answer) 
          }
        }
      end


    end
  end
end