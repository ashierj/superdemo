# frozen_string_literal: true

module EE
  module Members
    module MemberApproval
      extend ::Gitlab::Utils::Override
      extend ActiveSupport::Concern

      prepended do
        validate :validate_unique_pending_approval, on: [:create, :update]

        scope :pending_member_approvals, ->(member_namespace_id) do
          where(member_namespace_id: member_namespace_id).where(status: statuses[:pending])
        end
      end

      private

      def validate_unique_pending_approval
        return unless pending?

        scope = self.class.where(user_id: user_id, member_namespace_id: member_namespace_id,
          new_access_level: new_access_level, member_role_id: member_role_id, status: self.class.statuses[:pending])
        scope = scope.where.not(id: id) if persisted?
        return unless scope.exists?

        errors.add(:base, 'A pending approval for the same user, namespace, and access level already exists.')
      end
    end
  end
end
