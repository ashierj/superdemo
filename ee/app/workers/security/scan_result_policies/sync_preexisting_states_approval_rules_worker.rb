# frozen_string_literal: true

module Security
  module ScanResultPolicies
    class SyncPreexistingStatesApprovalRulesWorker
      include ApplicationWorker

      idempotent!
      data_consistency :always # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency -- this worker updates approval rules

      queue_namespace :security_scans
      feature_category :security_policy_management

      def perform(merge_request_id)
        merge_request = MergeRequest.find_by_id(merge_request_id)
        return unless merge_request

        return if Feature.disabled?(:security_policies_sync_preexisting_state, merge_request.project,
          type: :gitlab_com_derisk)

        Security::ScanResultPolicies::SyncPreexistingStatesApprovalRulesService.new(merge_request).execute
      end
    end
  end
end
