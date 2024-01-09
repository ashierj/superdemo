# frozen_string_literal: true

# Search for member roles

module MemberRoles
  class RolesFinder
    attr_reader :current_user, :params

    VALID_PARAMS = [:parent, :id, :instance_roles].freeze

    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params
    end

    def execute
      validate_arguments!

      items = MemberRole.all
      items = by_parent(items)
      items = by_id(items)
      items = for_instance(items)

      items.ordered_by_name
    end

    private

    def validate_arguments!
      raise ArgumentError, 'at least one filter param has to be provided' if valid_params.empty?
    end

    def valid_params
      params.delete(:instance_roles) unless can_read_instance_roles?
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

    def for_instance(items)
      return items if params[:instance_roles].blank?

      items.by_namespace(nil)
    end

    def root_ancestor
      params[:parent]&.root_ancestor
    end

    def can_read_instance_roles?
      # for SaaS only group level roles are allowed
      return false if saas?

      Ability.allowed?(current_user, :admin_member_role)
    end

    def allowed_group_ids(items)
      items.select { |item| allowed_read_member_role?(item.namespace) }.map(&:namespace_id)
    end

    def allowed_read_member_role?(group)
      return Ability.allowed?(current_user, :admin_member_role, group) if group
      return false if saas? # roles without group are not allowed for SaaS

      Ability.allowed?(current_user, :admin_member_role)
    end

    def saas?
      Gitlab::Saas.feature_available?(:group_custom_roles)
    end
  end
end
