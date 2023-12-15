# frozen_string_literal: true

module MemberRoles
  class CreateService < BaseService
    def execute
      return authorized_error unless allowed?
      return root_group_error if subgroup?

      create_member_role
    end

    private

    def allowed?
      return allowed_for_group? if group

      allowed_for_instance?
    end

    def allowed_for_group?
      group.custom_roles_enabled? && can?(current_user, :admin_member_role, group)
    end

    def allowed_for_instance?
      return false if saas?

      can?(current_user, :admin_member_role)
    end

    def root_group_error
      ::ServiceResponse.error(message: _('Creation of member role is allowed only for root groups'),
        reason: :unauthorized)
    end

    def subgroup?
      return false unless saas?

      !group.root?
    end

    def saas?
      Gitlab::Saas.feature_available?(:group_custom_roles)
    end

    def create_member_role
      member_role = MemberRole.new(params.merge(namespace: group))

      if member_role.save
        log_audit_event(member_role)

        ::ServiceResponse.success(payload: { member_role: member_role })
      else
        ::ServiceResponse.error(message: member_role.errors.full_messages.join(', '))
      end
    end

    def log_audit_event(member_role)
      audit_context = {
        name: 'member_role_created',
        author: current_user,
        scope: audit_event_scope,
        target: member_role,
        target_details: member_role.enabled_permissions.join(', '),
        message: "Member role #{member_role.name} was created"
      }

      ::Gitlab::Audit::Auditor.audit(audit_context)
    end

    def audit_event_scope
      group || Gitlab::Audit::InstanceScope.new
    end
  end
end
