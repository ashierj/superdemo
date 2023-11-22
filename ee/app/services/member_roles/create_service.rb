# frozen_string_literal: true

module MemberRoles
  class CreateService < BaseService
    def execute
      return authorized_error unless allowed?

      unless group.root?
        return ::ServiceResponse.error(message: _('Creation of member role is allowed only for root groups'))
      end

      create_member_role
    end

    private

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
        scope: group,
        target: member_role,
        target_details: member_role.enabled_permissions.join(', '),
        message: "Member role #{member_role.name} was created"
      }

      ::Gitlab::Audit::Auditor.audit(audit_context)
    end
  end
end
