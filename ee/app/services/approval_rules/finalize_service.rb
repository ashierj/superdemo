# frozen_string_literal: true

module ApprovalRules
  class FinalizeService
    attr_reader :merge_request

    def initialize(merge_request)
      @merge_request = merge_request
    end

    def execute
      return unless merge_request.merged?

      # fails ee/spec/services/approval_rules/finalize_service_spec.rb
      cross_join_issue = "https://gitlab.com/gitlab-org/gitlab/-/issues/417459"
      ::Gitlab::Database.allow_cross_joins_across_databases(url: cross_join_issue) do
        ApplicationRecord.transaction do
          if new_finalizing_approach?
            new_handling_of_rules
          else
            old_handling_of_rules
          end

          merge_request.approval_rules.each(&:sync_approved_approvers)
        end
      end
    end

    private

    def new_handling_of_rules
      if merge_request.approval_state.approval_rules_overwritten?
        new_merge_group_members_into_users
      else
        new_copy_project_rules
      end
    end

    def old_handling_of_rules
      if merge_request.approval_rules.regular.exists?
        old_merge_group_members_into_users
      else
        old_copy_project_approval_rules
      end
    end

    def new_finalizing_approach?
      Feature.enabled?(:use_new_rule_finalize_approach, merge_request.project)
    end

    def old_merge_group_members_into_users
      merge_request.approval_rules.each do |rule|
        rule.users |= rule.group_users
      end
    end

    def new_merge_group_members_into_users
      merge_request.approval_rules.each do |rule|
        rule.users |= rule.group_users
        applicable_post_merge = rule.applicable_to_branch?(merge_request.target_branch)

        rule.update!(applicable_post_merge: applicable_post_merge)
      end
    end

    def new_copy_project_rules
      attributes_to_slice = %w[approvals_required name report_type rule_type]

      # All User Defined MR rules are not applicable as we used project rules during merge
      # All other rules need to take into consideration if they are applicable or not
      applicable_ids = merge_request.approval_rules.not_regular_or_any_approver
        .applicable_to_branch(merge_request.target_branch)
        .map(&:id)

      merge_request.approval_rules.set_applicable_when_copying_rules(applicable_ids)

      merge_request.target_project.regular_or_any_approver_approval_rules.each do |project_rule|
        users = project_rule.approvers
        groups = project_rule.groups.public_or_visible_to_user(merge_request.author)
        applicable_post_merge = project_rule.applies_to_branch?(merge_request.target_branch)

        new_rule = merge_request.approval_rules.build(
          project_rule.attributes.slice(*attributes_to_slice)
          .merge(users: users, groups: groups,
            applicable_post_merge: applicable_post_merge)
        )

        if new_rule.valid?
          new_rule.save!
        else
          Gitlab::AppLogger.debug(
            "Failed to persist approval rule: #{new_rule.errors.full_messages}."
          )
        end
      end
    end

    # This freezes the approval state at the time of merge. By copying
    # project-level rules as merge request-level rules, the approval
    # state will be unaffected if project rules get changed or removed.
    def old_copy_project_approval_rules
      rules_by_name = merge_request.approval_rules.index_by(&:name)

      ff_enabled = Feature.enabled?(:copy_additional_properties_approval_rules, merge_request.project)
      attributes_to_slice = %w[approvals_required name]
      attributes_to_slice.append(*%w[rule_type report_type]) if ff_enabled

      merge_request.target_project.approval_rules.each do |project_rule|
        users = project_rule.approvers
        groups = project_rule.groups.public_or_visible_to_user(merge_request.author)
        name = project_rule.name

        next unless name.present?

        rule = rules_by_name[name]

        # If the rule already exists, we just skip this one without
        # updating the current state. If the approval rules were changed
        # after merging a merge request, syncing the data might make it
        # appear as though this merge request hadn't been approved.
        next if rule

        new_rule = merge_request.approval_rules.new(
          project_rule.attributes.slice(*attributes_to_slice).merge(users: users, groups: groups)
        )

        # If we fail to save with the new attributes, then let's default back to the simplified ones
        if new_rule.valid?
          new_rule.save!
        else
          Gitlab::AppLogger.debug(
            "Failed to persist approval rule: #{new_rule.errors.full_messages}. Defaulting to original rules"
          )

          merge_request.approval_rules.create!(
            project_rule.attributes.slice(*%w[approvals_required name]).merge(users: users, groups: groups)
          )
        end
      end
    end
  end
end
