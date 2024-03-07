# frozen_string_literal: true

module ApprovalRules
  module Updater
    include ::Audit::Changes

    def execute
      if group_rule? && Feature.disabled?(:approval_group_rules, rule.group)
        return ServiceResponse.error(message: "The feature approval_group_rules is not enabled.")
      end

      super
    end

    private

    def container
      return rule.group if group_rule?

      rule.project
    end

    def group_rule?
      rule.is_a?(ApprovalGroupRule)
    end

    def action
      filter_eligible_users!
      filter_eligible_groups!
      filter_eligible_protected_branches!

      update_rule ? success : error
    end

    def filter_eligible_users!
      return unless params.key?(:user_ids) || params.key?(:usernames)

      users = User.by_ids_or_usernames(params.delete(:user_ids), params.delete(:usernames))
      if group_container?
        filter_group_members(users)
      else
        filter_project_members(users)
      end
    end

    def filter_project_members(users)
      params[:users] = rule.project.members_among(users)
    end

    def filter_group_members(users)
      users_ids_of_direct_members = rule.group.users_ids_of_direct_members
      params[:users] = users.select { |user| users_ids_of_direct_members.include?(user.id) }
    end

    def filter_eligible_groups!
      return unless params.key?(:group_ids)

      group_ids = params.delete(:group_ids)

      params[:groups] = if params.delete(:permit_inaccessible_groups)
                          Group.id_in(group_ids)
                        else
                          Group.id_in(group_ids).accessible_to_user(current_user)
                        end
    end

    def filter_eligible_protected_branches!
      protected_branch_ids = params.delete(:protected_branch_ids)

      return unless protected_branch_ids && can_create_rule_for_protected_branches?

      params[:protected_branches] = ProtectedBranch.id_in(protected_branch_ids).for_project(project)

      return unless allow_protected_branches_for_group?(project.group) && project.root_namespace.is_a?(Group)

      params[:protected_branches] += ProtectedBranch.id_in(protected_branch_ids).for_group(project.root_namespace)
    end

    def allow_protected_branches_for_group?(group)
      ::Feature.enabled?(:group_protected_branches, group) ||
        ::Feature.enabled?(:allow_protected_branches_for_group, group)
    end

    def update_rule
      return rule.update(params) unless current_user

      audit_context = {
        name: rule.new_record? ? 'approval_rule_created' : 'update_approval_rules',
        author: current_user,
        scope: container,
        target: rule
      }

      ::Gitlab::Audit::Auditor.audit(audit_context) { rule.update(params) }
    end

    def success
      audit_changes_to_approvals_required if current_user

      rule.reset

      super
    end

    def audit_changes_to_approvals_required
      audit_changes(
        :approvals_required,
        as: 'number of required approvals',
        entity: container,
        model: rule,
        event_type: 'update_approval_rules'
      )
    end

    def can_create_rule_for_protected_branches?
      # Currently group approval rules support only all protected branches.
      return false if group_container? || !project.multiple_approval_rules_available?

      skip_authorization || can?(current_user, :admin_project, project)
    end
  end
end
