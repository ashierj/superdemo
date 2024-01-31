# frozen_string_literal: true

# Search for member roles

module MemberRoles
  class RolesFinder
    attr_reader :current_user, :params

    VALID_PARAMS = [:parent, :id, :instance_roles].freeze

    ALLOWED_SORT_VALUES = %i[id created_at name].freeze
    DEFAULT_SORT_VALUE = :name

    ALLOWED_SORT_DIRECTIONS = %i[asc desc].freeze
    DEFAULT_SORT_DIRECTION = :asc

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

      sort(items)
    end

    private

    def validate_arguments!
      raise ArgumentError, 'at least one filter param has to be provided' if valid_params.empty?
    end

    def valid_params
      params.delete(:instance_roles) unless allowed_read_member_role?(root_ancestor)
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

    def sort(items)
      order_by = ALLOWED_SORT_VALUES.include?(params[:order_by]) ? params[:order_by] : DEFAULT_SORT_VALUE
      order_direction = ALLOWED_SORT_DIRECTIONS.include?(params[:sort]) ? params[:sort] : DEFAULT_SORT_DIRECTION
      order_by = :id if order_by == :created_at

      items.order(order_by => order_direction) # rubocop:disable CodeReuse/ActiveRecord -- simple ordering
    end

    def for_instance(items)
      return items if params[:instance_roles].blank?

      # TODO: only return instance-level custom roles when
      # https://gitlab.com/gitlab-org/gitlab/-/issues/429281 is merged
      return items.or(MemberRole.for_instance) if params[:parent].present?

      items.for_instance
    end

    def root_ancestor
      params[:parent]&.root_ancestor
    end

    def can_read_instance_roles?
      return false if saas?

      Ability.allowed?(current_user, :admin_member_role)
    end

    def allowed_group_ids(items)
      items.select { |item| allowed_read_member_role?(item.namespace) }.map(&:namespace_id)
    end

    def allowed_read_member_role?(group)
      return Ability.allowed?(current_user, :admin_member_role, group) if group

      can_read_instance_roles?
    end

    def saas?
      Gitlab::Saas.feature_available?(:group_custom_roles)
    end
  end
end
