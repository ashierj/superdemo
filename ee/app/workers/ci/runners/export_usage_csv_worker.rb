# frozen_string_literal: true

module Ci
  module Runners
    # rubocop: disable Scalability/IdempotentWorker -- this worker sends out emails
    class ExportUsageCsvWorker
      include ApplicationWorker

      data_consistency :delayed

      sidekiq_options retry: 3

      feature_category :fleet_visibility
      worker_resource_boundary :cpu
      loggable_arguments 0, 1

      def perform(current_user_id, runner_type)
        user = User.find(current_user_id)

        result = Ci::Runners::SendUsageCsvService.new(current_user: user, runner_type: runner_type).execute
        log_extra_metadata_on_done(:status, result.status)
        log_extra_metadata_on_done(:message, result.message) if result.message
        log_extra_metadata_on_done(:csv_status, result.payload[:status]) if result.payload[:status]
      end
    end
    # rubocop: enable Scalability/IdempotentWorker
  end
end
