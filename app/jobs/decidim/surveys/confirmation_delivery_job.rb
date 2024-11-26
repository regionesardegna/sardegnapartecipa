# frozen_string_literal: true

module Decidim
  module Surveys
    class ConfirmationDeliveryJob < ApplicationJob
      queue_as :default

      def perform(user, questionnaire, answers)
        SurveyConfirmationMailer.confirmation(user, questionnaire, answers).deliver_now
      end
    end
  end
end