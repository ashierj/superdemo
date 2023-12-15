# frozen_string_literal: true

module Mutations
  module MemberRoles
    class Create < Base
      graphql_name 'MemberRoleCreate'

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
        required: ::Gitlab::Saas.feature_available?(:gitlab_saas_subscriptions),
        description: 'Group the member role to mutate is in. Required for SaaS.'
      argument :manage_project_access_tokens,
        GraphQL::Types::Boolean,
        required: false,
        description: 'Permission to admin project access tokens.'
      argument :permissions,
        [Types::MemberRoles::PermissionsEnum],
        required: false,
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
        group = ::Gitlab::Graphql::Lazy.force(find_object(group_path: args.delete(:group_path))) if args[:group_path]

        authorize_admin_roles!(group)

        params = canonicalize(args.merge(namespace: group))
        response = ::MemberRoles::CreateService.new(current_user, params).execute

        {
          member_role: response.payload[:member_role],
          errors: response.errors
        }
      end

      private

      def find_object(group_path:)
        resolve_namespace(full_path: group_path)
      end

      def authorize_admin_roles!(group)
        return authorize_group_member_roles!(group) if group

        authorize_instance_member_roles!
      end

      def authorize_group_member_roles!(group)
        raise_resource_not_available_error! unless Gitlab::Saas.feature_available?(:group_custom_roles)
        raise_resource_not_available_error! unless Ability.allowed?(current_user, :admin_member_role, group)
        raise_resource_not_available_error! unless group.custom_roles_enabled?
      end

      def authorize_instance_member_roles!
        raise_resource_not_available_error! unless Ability.allowed?(current_user, :admin_member_role)
        raise_resource_not_available_error! if Gitlab::Saas.feature_available?(:group_custom_roles)
      end

      def canonicalize(args)
        permissions = args.delete(:permissions) || []
        permissions.each_with_object(args) do |permission, new_args|
          new_args[permission.downcase] = true
        end
      end
    end
  end
end
