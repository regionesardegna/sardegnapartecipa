# frozen_string_literal: true

Rails.autoloaders.main.on_load("Decidim::Admin::LogsController") do |klass|
  klass.prepend(
    Module.new do
      private

      def search_field_predicate
        :user_name_or_user_nickname_or_user_email_cont
      end

      def logs
        super
        term = params.dig(:q, :user_name_or_user_nickname_or_user_email_cont)
        if term.present?
          matching_ids = Decidim::ActionLog.ransack(
            user_name_or_user_nickname_or_user_email_cont: term
          ).result.select(:id)
          @logs = @logs.where(id: matching_ids)
        end
        @logs
      end
    end
  )
end
