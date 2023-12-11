# frozen_string_literal: true

module EE
  module Ci
    module RetryPipelineService
      extend ::Gitlab::Utils::Override

      override :check_access
      def check_access(pipeline)
        if current_user && !current_user.has_required_credit_card_to_run_pipelines?(project)
          ServiceResponse.error(message: 'Credit card required to be on file in order to retry a pipeline', http_status: :forbidden)
        else
          super
        end
      end

      private

      override :builds_relation
      def builds_relation(pipeline)
        super.eager_load_tags
      end

      override :can_be_retried?
      def can_be_retried?(build)
        build_matcher = build.build_matcher
        super && runner_minutes.available?(build_matcher)
      end

      def runner_minutes
        ::Gitlab::Ci::RunnersAvailabilityBuilder.instance_for(project).minutes_checker
      end
    end
  end
end
