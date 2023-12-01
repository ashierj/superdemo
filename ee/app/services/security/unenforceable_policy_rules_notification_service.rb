# frozen_string_literal: true

module Security
  class UnenforceablePolicyRulesNotificationService
    include ::Security::ScanResultPolicies::PolicyViolationCommentGenerator

    def initialize(merge_request)
      @merge_request = merge_request
      @pipeline = merge_request.actual_head_pipeline
    end

    def execute
      notify_for_report_type(merge_request, :scan_finding, merge_request.approval_rules.scan_finding)
      notify_for_report_type(merge_request, :license_scanning, merge_request.approval_rules.license_scanning)
    end

    private

    attr_reader :merge_request, :pipeline

    delegate :project, to: :merge_request, private: true

    def notify_for_report_type(merge_request, report_type, approval_rules)
      return unless unenforceable_report?(report_type)

      applicable_rules = approval_rules.applicable_to_branch(merge_request.target_branch)

      generate_policy_bot_comment(merge_request, applicable_rules, report_type)
    end

    def unenforceable_report?(report_type)
      return true if pipeline.nil?

      case report_type
      when :scan_finding
        # Pipelines which can store security reports are handled via SyncFindingsToApprovalRulesService
        !pipeline.can_store_security_reports?
      when :license_scanning
        # Pipelines which have scanning results available are handled via SyncLicenseScanningRulesService
        !pipeline.can_ingest_sbom_reports?
      end
    end
  end
end
