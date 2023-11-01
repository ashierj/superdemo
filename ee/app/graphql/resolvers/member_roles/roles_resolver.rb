# frozen_string_literal: true

module Resolvers
  module MemberRoles
    class RolesResolver < BaseResolver
      type Types::MemberRoles::MemberRoleType, null: true

      argument :id, ::Types::GlobalIDType[::MemberRole],
        required: false,
        description: 'Global ID of the member role to look up.'

      def resolve(id: nil)
        params = { parent: object }
        params[:id] = id.model_id if id.present?

        member_roles = ::MemberRoles::RolesFinder.new(current_user, params).execute

        offset_pagination(member_roles)
      end
    end
  end
end
