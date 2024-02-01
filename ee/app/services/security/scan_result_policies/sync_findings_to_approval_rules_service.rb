# frozen_string_literal: true

module Security
  module ScanResultPolicies
    class SyncFindingsToApprovalRulesService
      def initialize(pipeline)
        @pipeline = pipeline
      end

      def execute
        sync_scan_finding
      end

      private

      attr_reader :pipeline

      def sync_scan_finding
        return if pipeline.security_findings.empty? && !pipeline.complete?

        update_required_approvals_for_scan_finding
      end

      def update_required_approvals_for_scan_finding
        merge_requests_for_pipeline.each do |merge_request|
          update_approvals(merge_request)
        end

        # Ensure that approvals are in sync when the source branch pipeline
        # finishes before the target branch pipeline
        merge_requests_targeting_pipeline_ref.each do |merge_request|
          head_pipeline = merge_request.actual_head_pipeline || next

          Security::ScanResultPolicies::SyncMergeRequestApprovalsWorker.perform_async(
            head_pipeline.id,
            merge_request.id)
        end
      end

      def update_approvals(merge_request)
        Security::ScanResultPolicies::SyncMergeRequestApprovalsWorker.perform_async(pipeline.id, merge_request.id)
      end

      def merge_requests_for_pipeline
        return MergeRequest.none unless pipeline.latest?

        pipeline.all_merge_requests.opened
      end

      def merge_requests_targeting_pipeline_ref
        return MergeRequest.none unless pipeline.latest?

        pipeline
          .project
          .merge_requests
          .opened
          .by_target_branch(pipeline.ref)
      end
    end
  end
end
