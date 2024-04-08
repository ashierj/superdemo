# frozen_string_literal: true

module Security
  module ScanResultPolicies
    class SyncFindingsToApprovalRulesService
      def initialize(pipeline)
        @project = pipeline.project
        @pipeline = if pipeline.child? && Feature.enabled?(:approval_policy_parent_child_pipeline, project)
                      pipeline.root_ancestor
                    else
                      pipeline
                    end
      end

      def execute
        sync_scan_finding
      end

      private

      attr_reader :pipeline, :project

      def sync_scan_finding
        return unless Enums::Ci::Pipeline.ci_and_security_orchestration_sources.key?(pipeline.source.to_sym)

        pipeline_complete = if pipeline.include_manual_to_pipeline_completion_enabled?
                              pipeline.complete_or_manual?
                            else
                              pipeline.complete?
                            end

        return if !pipeline_complete && !pipeline_has_security_findings?

        update_required_approvals_for_scan_finding
      end

      def update_required_approvals_for_scan_finding
        merge_requests_for_pipeline.each do |merge_request|
          update_approvals(merge_request)
        end

        # Ensure that approvals are in sync when the source branch pipeline
        # finishes before the target branch pipeline
        merge_requests_targeting_pipeline_ref.each do |merge_request|
          head_pipeline = merge_request.diff_head_pipeline || next

          Security::ScanResultPolicies::SyncMergeRequestApprovalsWorker.perform_async(
            head_pipeline.id,
            merge_request.id)
        end
      end

      def pipeline_has_security_findings?
        return pipeline.has_security_findings_in_self_and_descendants? if approval_policy_parent_child_pipeline_enabled?

        pipeline.has_security_findings?
      end

      def approval_policy_parent_child_pipeline_enabled?
        Feature.enabled?(:approval_policy_parent_child_pipeline, project)
      end

      def update_approvals(merge_request)
        Security::ScanResultPolicies::SyncMergeRequestApprovalsWorker.perform_async(pipeline.id, merge_request.id)
      end

      def merge_requests_for_pipeline
        pipeline.all_merge_requests.opened.select do |mr|
          mr.head_sha_pipeline?(pipeline)
        end
      end

      def merge_requests_targeting_pipeline_ref
        return MergeRequest.none unless pipeline.latest?

        project
          .merge_requests
          .opened
          .by_target_branch(pipeline.ref)
      end
    end
  end
end
