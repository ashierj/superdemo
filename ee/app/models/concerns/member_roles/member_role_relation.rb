# frozen_string_literal: true

module MemberRoles
  module MemberRoleRelation
    extend ActiveSupport::Concern

    included do
      belongs_to :member_role

      validate :validate_member_role_access_level
      validate :validate_access_level_locked_for_member_role, on: :update
      validate :validate_member_role_belongs_to_same_root_namespace

      cattr_accessor :base_access_level_attr

      def self.base_access_level_attr(attr)
        self.base_access_level_attr = attr
      end
    end

    def set_access_level_based_on_member_role
      if member_role && group.custom_roles_enabled?
        self[base_access_level_attr] = member_role.base_access_level
      else
        self.member_role_id = nil
      end
    end

    private

    def validate_member_role_access_level
      return unless member_role_id && group.custom_roles_enabled?
      return if self[base_access_level_attr] == member_role.base_access_level

      errors.add(:member_role_id, _("the custom role's base access level does not match the current access level"))
    end

    def validate_access_level_locked_for_member_role
      return unless member_role_id && group.custom_roles_enabled?
      return if member_role_changed? # it is ok to change the access level when changing the member role
      return unless changed.include?(base_access_level_attr.to_s)

      errors.add(base_access_level_attr,
        _('cannot be changed because of an existing association with a custom role'))
    end

    def validate_member_role_belongs_to_same_root_namespace
      return unless member_role_id && group.custom_roles_enabled?
      return unless member_role.namespace_id
      return if group.id == member_role.namespace_id

      errors.add(:group, _("must belong to the same namespace as the custom role's namespace"))
    end
  end
end
