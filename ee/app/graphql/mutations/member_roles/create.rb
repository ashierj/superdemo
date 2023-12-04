# frozen_string_literal: true

module Mutations
  module MemberRoles
    class Create < Base
      graphql_name 'MemberRoleCreate'

      authorize :admin_group

      include Mutations::ResolvesNamespace

      argument :admin_group_member,
        GraphQL::Types::Boolean,
        required: false,
        description: 'Permission to admin group members.'
      argument :admin_merge_request,
        GraphQL::Types::Boolean,
        required: false,
        description: 'Permission to admin merge requests.'
      argument :admin_vulnerability,
        GraphQL::Types::Boolean,
        required: false,
        description: 'Permission to admin vulnerability.'
      argument :archive_project,
        GraphQL::Types::Boolean,
        required: false,
        description: 'Permission to archive projects.'
      argument :base_access_level,
        ::Types::MemberAccessLevelEnum,
        required: true,
        description: 'Base access level for the custom role.'
      argument :group_path, GraphQL::Types::ID,
        required: true,
        description: 'Group the member role to mutate is in.'
      argument :manage_project_access_tokens,
        GraphQL::Types::Boolean,
        required: false,
        description: 'Permission to admin project access tokens.'
      argument :permissions,
        [GraphQL::Types::String],
        required: false,
        alpha: { milestone: '16.7' },
        description: 'List of all customizable permissions.'
      argument :read_code,
        GraphQL::Types::Boolean,
        required: false,
        description: 'Permission to read code.'
      argument :read_dependency,
        GraphQL::Types::Boolean,
        required: false,
        description: 'Permission to read dependency.'
      argument :read_vulnerability,
        GraphQL::Types::Boolean,
        required: false,
        description: 'Permission to read vulnerability.'

      def resolve(args)
        group = authorized_find!(group_path: args.delete(:group_path))
        raise_resource_not_available_error! unless group.custom_roles_enabled?
        response = ::MemberRoles::CreateService.new(group, current_user, canonicalize(args)).execute

        {
          member_role: response.payload[:member_role],
          errors: response.errors
        }
      end

      private

      def find_object(group_path:)
        resolve_namespace(full_path: group_path)
      end

      def canonicalize(args)
        permissions = args.delete(:permissions) || []
        permissions.each_with_object(args) { |permission, new_args| new_args[permission] = true }
      end
    end
  end
end
