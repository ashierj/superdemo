# frozen_string_literal: true

module ApprovalRuleLike
  extend ActiveSupport::Concern

  DEFAULT_NAME = 'Default'

  included do
    has_and_belongs_to_many :users
    has_and_belongs_to_many :groups, class_name: 'Group', join_table: "#{self.table_name}_groups"
    has_many :group_users, through: :groups, source: :users

    validates :name, presence: true
  end

  # Users who are eligible to approve, including specified group members.
  # @return [Array<User>]
  def approvers
    @approvers ||= User.from_union([users, group_users])
  end

  def add_member(member)
    case member
    when User
      users << member unless users.exists?(member.id)
    when Group
      groups << member unless groups.exists?(member.id)
    end
  end

  def remove_member(member)
    case member
    when User
      users.delete(member)
    when Group
      groups.delete(member)
    end
  end
end
