# frozen_string_literal: true

module EE
  module Members
    module CreatorService
      extend ::Gitlab::Utils::Override

      private

      override :member_attributes
      def member_attributes
        super.merge(ldap: ldap)
      end

      override :after_commit_tasks
      def after_commit_tasks
        super

        finish_onboarding_user
      end

      override :commit_member
      def commit_member
        if security_bot_and_member_of_other_project?
          member.errors.add(:base, _('security policy bot users cannot be added to other projects'))
        else
          super
        end
      end

      def finish_onboarding_user
        return unless ::Onboarding.user_onboarding_in_progress?(member.user)
        return unless finished_welcome_step?

        member.user.update(onboarding_step_url: nil, onboarding_in_progress: false)
      end

      def finished_welcome_step?
        member.user.role?
      end

      def security_bot_and_member_of_other_project?
        return false unless member.user&.security_policy_bot?

        ::Member.exists?(user_id: member.user.id) # rubocop:disable CodeReuse/ActiveRecord
      end
    end
  end
end
