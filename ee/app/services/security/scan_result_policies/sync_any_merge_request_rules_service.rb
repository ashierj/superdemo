# frozen_string_literal: true

module Security
  module ScanResultPolicies
    class SyncAnyMergeRequestRulesService
      include ::Security::ScanResultPolicies::PolicyViolationCommentGenerator

      def initialize(merge_request)
        @merge_request = merge_request
        @violations = Security::SecurityOrchestrationPolicies::UpdateViolationsService.new(merge_request)
      end

      def execute
        return if merge_request.merged?

        sync_approval_rules(merge_request)
        violations.execute
      end

      private

      attr_reader :merge_request, :violations

      def sync_approval_rules(merge_request)
        approval_rules = merge_request.approval_rules.any_merge_request
        return if approval_rules.empty?

        violated_rules, unviolated_rules = partition_rules(approval_rules)

        violated_rules, _ = update_required_approvals(violated_rules, unviolated_rules)
        generate_policy_bot_comment(merge_request, violated_rules, :any_merge_request)
        log_violated_rules(violated_rules)
        violations.add(violated_rules)
      end

      def partition_rules(approval_rules)
        has_unsigned_commits = !merge_request.commits(load_from_gitaly: true).all?(&:has_signature?)
        approval_rules.including_scan_result_policy_read.partition do |approval_rule|
          scan_result_policy_read = approval_rule.scan_result_policy_read
          scan_result_policy_read.commits_any? ||
            (scan_result_policy_read.commits_unsigned? && has_unsigned_commits)
        end
      end

      def update_required_approvals(violated_rules, unviolated_rules)
        updated_violated_rules = merge_request.reset_required_approvals(violated_rules)
        ApprovalMergeRequestRule.remove_required_approved(unviolated_rules)
        [updated_violated_rules, unviolated_rules]
      end

      def log_violated_rules(rules)
        return unless rules.any?

        rules.each do |approval_rule|
          log_violated_rule(
            approval_rule_id: approval_rule.id,
            approval_rule_name: approval_rule.name
          )
        end
      end

      def log_violated_rule(**attributes)
        default_attributes = {
          reason: 'any_merge_request rule violated',
          event: 'update_approvals',
          merge_request_id: merge_request.id,
          merge_request_iid: merge_request.iid,
          project_path: merge_request.project.full_path
        }
        Gitlab::AppJsonLogger.info(message: 'Updating MR approval rule', **default_attributes.merge(attributes))
      end
    end
  end
end
