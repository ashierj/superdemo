# frozen_string_literal: true

module EE
  module Admin
    module AbuseReportDetailsEntity
      extend ActiveSupport::Concern

      prepended do
        expose :user, if: ->(report) { report.user } do
          expose :plan do |report|
            if ::Gitlab::CurrentSettings.current_application_settings.try(:should_check_namespace_plan?)
              report.user.namespace&.actual_plan&.title
            end
          end
        end
      end
    end
  end
end
