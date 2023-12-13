# frozen_string_literal: true

class MemberRole < ApplicationRecord # rubocop:disable Gitlab/NamespacedClass
  MAX_COUNT_PER_GROUP_HIERARCHY = 10

  NON_PERMISSION_COLUMNS = [
    :base_access_level,
    :created_at,
    :description,
    :id,
    :name,
    :namespace_id,
    :updated_at
  ].freeze
  LEVELS = ::Gitlab::Access.options_with_owner.values.freeze

  has_many :members
  has_many :saml_providers
  has_many :saml_group_links
  belongs_to :namespace

  validates :namespace, presence: true, if: :group_role_required?
  validates :name, presence: true
  validates :base_access_level, presence: true, inclusion: { in: LEVELS }
  validate :belongs_to_top_level_namespace
  validate :max_count_per_group_hierarchy, on: :create
  validate :validate_namespace_locked, on: :update
  validate :attributes_locked_after_member_associated, on: :update
  validate :validate_requirements

  validates_associated :members

  scope :elevating, -> do
    return none if elevating_permissions.empty?

    query = elevating_permissions.map { |permission| "#{permission} = true" }
                                 .join(" OR ")
    where(query)
  end

  scope :ordered_by_name, -> { order(:name) }
  scope :by_namespace, ->(group_ids) { where(namespace_id: group_ids) }

  scope :with_members_count, -> do
    left_outer_joins(:members)
      .group(:id)
      .select(MemberRole.default_select_columns)
      .select('COUNT(members.id) AS members_count')
  end

  before_destroy :prevent_delete_after_member_associated

  def self.levels_sentence
    ::Gitlab::Access
      .options_with_owner
      .map { |name, value| "#{value} (#{name})" }
      .to_sentence
  end

  def self.declarative_policy_class
    'Members::MemberRolePolicy'
  end

  class << self
    def elevating_permissions
      all_customizable_permissions.keys - customizable_permissions_exempt_from_consuming_seat
    end

    def all_customizable_permissions
      Gitlab::CustomRoles::Definition.all
    end

    def all_customizable_project_permissions
      MemberRole.all_customizable_permissions.select { |_k, v| v[:project_ability] }.keys
    end

    def all_customizable_group_permissions
      MemberRole.all_customizable_permissions.select { |_k, v| v[:group_ability] }.keys
    end

    def customizable_permissions_exempt_from_consuming_seat
      MemberRole.all_customizable_permissions.select { |_k, v| v[:skip_seat_consumption] }.keys
    end
  end

  def enabled_permissions
    MemberRole.all_customizable_permissions.keys.filter { |perm| attributes[perm.to_s] }
  end

  private

  def belongs_to_top_level_namespace
    return if !namespace || namespace.root?

    errors.add(:namespace, s_("MemberRole|must be top-level namespace"))
  end

  def max_count_per_group_hierarchy
    return unless namespace
    return if namespace.member_roles.count < MAX_COUNT_PER_GROUP_HIERARCHY

    errors.add(
      :namespace,
      s_(
        "MemberRole|maximum number of Member Roles are already in use by the group hierarchy. " \
        "Please delete an existing Member Role."
      )
    )
  end

  def validate_namespace_locked
    return unless namespace_id_changed?

    errors.add(:namespace, s_("MemberRole|can't be changed"))
  end

  def validate_requirements
    self.class.all_customizable_permissions.each do |permission, params|
      requirement = params[:requirement]

      next unless self[permission] # skipping permissions not set for the object
      next unless requirement # skipping permissions that have no requirement
      next if self[requirement] # the requierement is met

      errors.add(permission,
        format(s_("MemberRole|%{requirement} has to be enabled in order to enable %{permission}."),
          requirement: requirement, permission: permission)
      )
    end
  end

  def attributes_locked_after_member_associated
    return unless members.present?
    return if changed_attributes.except('name', 'description').empty?

    errors.add(
      :base,
      s_(
        "MemberRole|cannot be changed because it is already assigned to a user. " \
        "Please create a new Member Role instead"
      )
    )
  end

  def prevent_delete_after_member_associated
    return unless members.present?

    errors.add(
      :base,
      s_(
        "MemberRole|cannot be deleted because it is already assigned to a user. " \
        "Please disassociate the member role from all users before deletion."
      )
    )

    throw :abort # rubocop:disable Cop/BanCatchThrow
  end

  def group_role_required?
    Gitlab::Saas.feature_available?(:group_custom_roles)
  end
end
