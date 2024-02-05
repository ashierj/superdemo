# frozen_string_literal: true

module EE
  module ResolvesMergeRequests
    extend ActiveSupport::Concern

    private

    def preloads
      super.tap do |h|
        h[:mergeable] = [
          *approved_mergeability_check_preloads,
          *broken_status_mergeability_check_preloads
        ]

        h[:detailed_merge_status] = [
          *approved_mergeability_check_preloads,
          *broken_status_mergeability_check_preloads
        ]
      end
    end

    def broken_status_mergeability_check_preloads
      [:latest_merge_request_diff]
    end

    def approved_mergeability_check_preloads
      [
        :approvals,
        :approved_by_users,
        :scan_result_policy_violations,
        {
          applicable_post_merge_approval_rules: [
            :approved_approvers,
            *approval_merge_request_rules_preloads
          ],
          approval_rules: approval_merge_request_rules_preloads,
          target_project: [
            regular_or_any_approver_approval_rules: approval_project_rules_preloads
          ]
        }
      ]
    end

    def approval_rules_preloads
      [
        :group_users,
        :users
      ]
    end

    def approval_merge_request_rules_preloads
      [
        *approval_rules_preloads,
        { approval_project_rule: approval_project_rules_preloads }
      ]
    end

    def approval_project_rules_preloads
      [
        :protected_branches,
        *approval_rules_preloads
      ]
    end
  end
end
