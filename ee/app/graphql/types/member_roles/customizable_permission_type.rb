# frozen_string_literal: true

module Types
  module MemberRoles
    # rubocop: disable Graphql/AuthorizeTypes
    class CustomizablePermissionType < BaseObject
      graphql_name 'CustomizablePermission'

      field :available_for, [GraphQL::Types::String], null: false,
        description: 'Objects the permission is available for.'
      field :description, GraphQL::Types::String, null: true, description: 'Description of the permission.'
      field :name, GraphQL::Types::String, null: false,
        description: 'Localized name of the permission.'
      field :requirement, GraphQL::Types::String, null: true, description: 'Requirement of the permission.'
      field :value, GraphQL::Types::String, null: false, description: 'Value of the permission.'

      def available_for
        symbolized_value = object[:value].downcase.to_sym

        result = []
        result << :project if MemberRole.all_customizable_project_permissions.include?(symbolized_value)
        result << :group if MemberRole.all_customizable_group_permissions.include?(symbolized_value)

        result
      end

      def description
        _(object[:description])
      end

      def name
        _(object[:value].to_s.humanize)
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
