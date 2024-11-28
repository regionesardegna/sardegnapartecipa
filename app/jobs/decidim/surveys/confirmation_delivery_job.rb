# Copyright (C) 2024 Sardegna IT
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, version 3.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>

# Aggiunto per gestire la notifica utente per le surveys 

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