# frozen_string_literal: true

module Members
  class MemberRolePolicy < BasePolicy
    delegate { @subject.namespace }

    condition(:custom_roles_allowed) do
      ::License.feature_available?(:custom_roles)
    end

    rule { admin & custom_roles_allowed }.policy do
      enable :admin_member_role
    end
  end
end
