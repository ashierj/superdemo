# frozen_string_literal: true

module Types
  module MemberRoles
    class MemberRoleType < BaseObject
      graphql_name 'MemberRole'
      description 'Represents a member role'

      authorize :admin_member_role

      field :id,
        ::Types::GlobalIDType[::MemberRole],
        null: false,
        description: 'ID of the member role.'

      field :name,
        GraphQL::Types::String,
        null: false,
        description: 'Name of the member role.'

      field :description,
        GraphQL::Types::String,
        null: true,
        description: 'Description of the member role.'

      field :base_access_level,
        Types::AccessLevelType,
        null: false,
        alpha: { milestone: '16.5' },
        description: 'Base access level for the custom role.'

      field :enabled_permissions,
        ::Types::MemberRoles::CustomizablePermissionType.connection_type,
        null: false,
        alpha: { milestone: '16.5' },
        description: 'Array of all permissions enabled for the custom role.'

      field :members_count,
        GraphQL::Types::Int,
        null: false,
        alpha: { milestone: '16.7' },
        description: 'Total number of members with the custom role.'

      def members_count
        return object.members_count if object.respond_to?(:members_count)

        object.members.count
      end
    end
  end
end
