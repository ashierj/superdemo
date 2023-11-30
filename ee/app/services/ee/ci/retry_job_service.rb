# frozen_string_literal: true

module EE
  module Ci
    module RetryJobService
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      private

      override :check_access!
      def check_access!(build)
        super

        if current_user && !current_user.has_required_credit_card_to_run_pipelines?(project)
          ::Gitlab::AppLogger.info(
            message: 'Credit card required to be on file in order to retry build',
            project_path: project.full_path,
            user_id: current_user.id,
            plan: project.root_namespace.actual_plan_name
          )

          raise ::Gitlab::Access::AccessDeniedError, 'Credit card required to be on file in order to retry a build'
        end
      end

      override :check_assignable_runners!
      def check_assignable_runners!(build)
        build_matcher = build.build_matcher
        build.drop!(:ci_quota_exceeded) unless runner_minutes.available?(build_matcher)
      end

      def runner_minutes
        ::Gitlab::Ci::RunnersAvailabilityBuilder.instance_for(project).minutes_checker
      end
    end
  end
end
