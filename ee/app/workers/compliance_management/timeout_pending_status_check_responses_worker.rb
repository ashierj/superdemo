# frozen_string_literal: true

module ComplianceManagement
  class TimeoutPendingStatusCheckResponsesWorker
    include ApplicationWorker

    # This worker does not schedule other workers that require context.
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    idempotent!
    feature_category :compliance_management
    data_consistency :always # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency
    urgency :high

    def perform
      return unless Feature.enabled?(:timeout_status_check_responses)

      ::MergeRequests::StatusCheckResponse.pending.each_batch do |batch|
        batch.timeout_eligible.update_all(status: 'failed')
      end
    end
  end
end
