# frozen_string_literal: true

module Types
  module MemberRoles
    # rubocop: disable Graphql/AuthorizeTypes
    class CustomizablePermissionType < BaseObject
      graphql_name 'CustomizablePermission'

      field :available_for,
        type: [GraphQL::Types::String],
        null: false,
        description: 'Objects the permission is available for.'

      field :description,
        type: GraphQL::Types::String,
        null: true,
        description: 'Description of the permission.'

      field :name,
        type: GraphQL::Types::String,
        null: false,
        description: 'Localized name of the permission.'

      field :requirement,
        type: Types::MemberRoles::PermissionsEnum,
        null: true,
        description: 'Requirement of the permission.'

      field :value,
        type: Types::MemberRoles::PermissionsEnum,
        null: false,
        description: 'Value of the permission.',
        method: :itself

      def available_for
        result = []
        result << :project if MemberRole.all_customizable_project_permissions.include?(object)
        result << :group if MemberRole.all_customizable_group_permissions.include?(object)

        result
      end

      def description
        _(permission[:description])
      end

      def name
        _(object.to_s.humanize)
      end

      def requirement
        permission[:requirement].presence&.to_sym
      end

      def permission
        MemberRole.all_customizable_permissions[object]
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
