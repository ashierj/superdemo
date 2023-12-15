# frozen_string_literal: true

module MemberRoles
  class DeleteService < BaseService
    def execute(member_role)
      @member_role = member_role

      return authorized_error unless allowed?

      if member_role.destroy
        ::ServiceResponse.success(payload: {
          member_role: member_role
        })
      else
        ::ServiceResponse.error(
          message: member_role.errors.full_messages,
          payload: { member_role: member_role }
        )
      end
    end
  end
end
