# frozen_string_literal: true

# Copyright (C) 2025 Sardegna IT
#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Modificato per gestire la notifica utente per le surveys

# DA VERIFICARE

module Decidim
  module Surveys
    class SurveyConfirmationMailer < ApplicationMailer
      include TranslatableAttributes
      helper Decidim::SanitizeHelper
      
      layout "mailer"

      def confirmation(user, questionnaire, answers)
        return if answers.blank? || user.nil?

        with_user(user) do
          @user = user
          @questionnaire_title = translated_attribute(questionnaire.title)
          @participatory_space_title = translated_attribute(questionnaire.questionnaire_for.component.participatory_space.title)
          @questionnaire_slug = questionnaire.questionnaire_for.component.participatory_space.slug.to_s
          @organization = user.organization
          add_file_with_answers(answers)
          bcc_address = ENV['SURVEYS_NOTIFICATION_BCC_ADDRESS']
          mail(to: "#{@user.name} <#{@user.email}>", bcc: bcc_address, subject: t(".subject", questionnaire_title: @questionnaire_title, participatory_space_title: @participatory_space_title))
        end
      end

      private

      def add_file_with_answers(answers)
        export_name = t("decidim.surveys.survey_confirmation_mailer.export_name", questionnaire_slug: @questionnaire_slug)
        serializer = Decidim::Forms::UserAnswersSerializer
        export_data = Decidim::Exporters::FormPDF.new(@organization, answers, serializer).export
        filename = export_data.filename(export_name)
        filename_without_extension = export_data.filename(export_name, extension: false)
        attachments["#{filename_without_extension}.zip"] = FileZipper.new(filename, export_data.read).zip
      end
    end
  end
end