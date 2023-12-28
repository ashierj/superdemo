# frozen_string_literal: true

module Mutations
  module MemberRoles
    class Create < Base
      graphql_name 'MemberRoleCreate'

      include Mutations::ResolvesNamespace

      argument :base_access_level,
        ::Types::MemberAccessLevelEnum,
        required: true,
        description: 'Base access level for the custom role.'
      argument :group_path, GraphQL::Types::ID,
        required: ::Gitlab::Saas.feature_available?(:gitlab_saas_subscriptions),
        description: 'Group the member role to mutate is in. Required for SaaS.'

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
