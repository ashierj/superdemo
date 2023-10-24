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

        remove_required_approvals
        violations.execute
      end

      private

      attr_reader :merge_request, :violations

      def remove_required_approvals
        related_policies = merge_request.project.scan_result_policy_reads.targeting_commits
        return if related_policies.empty?

        violated_policies_ids, unviolated_policies_ids = evaluate_policy_violations(related_policies)

        violated_rules, unviolated_rules = rules_for_violated_policies(violated_policies_ids)
        violated_rules, unviolated_rules = update_required_approvals(violated_rules, unviolated_rules)

        generate_policy_bot_comment(merge_request, violated_rules, :any_merge_request)
        log_violated_rules(violated_rules)
        # rubocop:disable CodeReuse/ActiveRecord
        violations.add(
          violated_policies_ids - unviolated_rules.pluck(:scan_result_policy_id),
          unviolated_policies_ids + unviolated_rules.pluck(:scan_result_policy_id)
        )
        # rubocop:enable CodeReuse/ActiveRecord
      end

      def evaluate_policy_violations(scan_result_policy_reads)
        has_unsigned_commits = !merge_request.commits(load_from_gitaly: true).all?(&:has_signature?)
        violated, unviolated = scan_result_policy_reads.partition do |scan_result_policy_read|
          scan_result_policy_read.commits_any? ||
            (scan_result_policy_read.commits_unsigned? && has_unsigned_commits)
        end
        [violated.pluck(:id), unviolated.pluck(:id)] # rubocop:disable CodeReuse/ActiveRecord
      end

      def rules_for_violated_policies(violated_policies_ids)
        approval_rules = merge_request.approval_rules.any_merge_request
        approval_rules_for_target_branch = approval_rules.applicable_to_branch(merge_request.target_branch)

        violated_rules = approval_rules_for_policies(approval_rules_for_target_branch, violated_policies_ids)
        unviolated_rules = approval_rules - violated_rules

        [violated_rules, unviolated_rules]
      end

      def update_required_approvals(violated_rules, unviolated_rules)
        updated_violated_rules = merge_request.reset_required_approvals(violated_rules)
        ApprovalMergeRequestRule.remove_required_approved(unviolated_rules) if unviolated_rules.any?
        [updated_violated_rules, unviolated_rules]
      end

      def approval_rules_for_policies(approval_rules, policies_ids)
        approval_rules.select { |rule| policies_ids.include? rule.scan_result_policy_id }
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
