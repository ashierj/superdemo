# frozen_string_literal: true

# Search for member roles

module MemberRoles
  class RolesFinder
    attr_reader :current_user, :params

    VALID_PARAMS = [:parent, :id].freeze

    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params
    end

    def execute
      validate_arguments!

      items = MemberRole.all
      items = by_parent(items)
      items = by_id(items)

      items.ordered_by_name
    end

    private

    def validate_arguments!
      raise ArgumentError, 'at least one filter param has to be provided' if valid_params.empty?
    end

    def valid_params
      params.slice(*VALID_PARAMS)
    end

    def by_parent(items)
      return items if params[:parent].blank?

      return MemberRole.none unless allowed_read_member_role?(root_ancestor)

      root_ancestor.member_roles
    end

    def by_id(items)
      return items if params[:id].blank?

      items = items.id_in(params[:id])

      items.by_namespace(allowed_group_ids(items))
    end

    def root_ancestor
      params[:parent]&.root_ancestor
    end

    def allowed_group_ids(items)
      items.select { |item| allowed_read_member_role?(item.namespace) }.map(&:namespace_id)
    end

    def allowed_read_member_role?(group)
      return false unless Ability.allowed?(current_user, :admin_group_member, group)

      group.custom_roles_enabled?
    end
  end
end
