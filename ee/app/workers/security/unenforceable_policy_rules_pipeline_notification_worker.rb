# frozen_string_literal: true

module Security
  class UnenforceablePolicyRulesPipelineNotificationWorker
    include ApplicationWorker

    idempotent!
    data_consistency :sticky
    feature_category :security_policy_management

    def perform(pipeline_id)
      pipeline = ::Ci::Pipeline.find_by_id(pipeline_id)
      return unless pipeline

      project = pipeline.project
      return unless project.licensed_feature_available?(:security_orchestration_policies)
      return if project.approval_rules.with_scan_result_policy_read.none?

      pipeline.opened_merge_requests_with_head_sha.each do |merge_request|
        Security::UnenforceablePolicyRulesNotificationService.new(merge_request).execute
      end
    end
  end
end
