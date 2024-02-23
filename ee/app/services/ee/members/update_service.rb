# frozen_string_literal: true

module EE
  module Members
    module UpdateService
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(members, permission: :update)
        return super unless non_admin_and_member_promotion_management_enabled?

        members = Array.wrap(members)
        members_to_update, members_requiring_approval = split_members_requiring_update_and_approval(members)

        if members_requiring_approval.present?
          members_queued_for_approval = queue_members_for_approval(members_requiring_approval, permission)
          if members_queued_for_approval.empty?
            return error("Invalid record while enqueuing members for approval", pass_back: {
              members: members_requiring_approval
            })
          end
        end

        response = super(members_to_update, permission: permission)
        return response if response[:status] == :error

        response.merge(members_queued_for_approval: members_queued_for_approval)
      end

      override :after_execute
      def after_execute(action:, old_access_level:, old_expiry:, member:)
        super

        log_audit_event(old_access_level: old_access_level, old_expiry: old_expiry, member: member)
      end

      private

      override :has_update_permissions?
      def has_update_permissions?(member, permission)
        super && !member_role_too_high?(member)
      end

      def member_role_too_high?(member)
        return false unless params[:access_level] # we don't update access_level

        member.prevent_role_assignement?(current_user, params.merge(current_access_level: member.access_level))
      end

      def split_members_requiring_update_and_approval(members)
        members_to_queue, members_to_update = members.partition do |member|
          member.member_promotion_management_required?(params[:access_level])
        end

        [members_to_update, members_to_queue]
      end

      def queue_members_for_approval(members_to_queue, permission)
        ::Members::MemberApproval.transaction do
          members_to_queue.map do |member|
            raise ::Gitlab::Access::AccessDeniedError unless has_update_permissions?(member, permission)

            member.queue_for_approval(params[:access_level], current_user)
          end
        end
      rescue ActiveRecord::RecordInvalid
        []
      end

      def non_admin_and_member_promotion_management_enabled?
        return false if current_user.can_admin_all_resources?

        ::Feature.enabled?(:member_promotion_management, type: :wip) &&
          ::Gitlab::CurrentSettings.enable_member_promotion_management?
      end

      override :update_member
      def update_member(member, permission)
        handle_member_role_assignement(member) if params.key?(:member_role_id)

        super
      end

      def handle_member_role_assignement(member)
        top_level_group = member.source.root_ancestor

        params.delete(:member_role_id) unless top_level_group.custom_roles_enabled?

        return unless params[:member_role_id]

        # TODO: scope to group/instance based on saas? mode when
        # https://gitlab.com/gitlab-org/gitlab/-/issues/429281 is merged
        member_role = MemberRole.find_by_id(params[:member_role_id])

        unless member_role
          member.errors.add(:member_role, "not found")
          params.delete(:member_role_id)

          return
        end

        return if params[:access_level]

        params[:access_level] ||= member_role.base_access_level
      end

      def log_audit_event(old_access_level:, old_expiry:, member:)
        audit_context = {
          name: 'member_updated',
          author: current_user || ::Gitlab::Audit::UnauthenticatedAuthor.new(name: '(System)'),
          scope: member.source,
          target: member.user || ::Gitlab::Audit::NullTarget.new,
          target_details: member.user&.name || 'Updated Member',
          message: 'Membership updated',
          additional_details: {
            change: 'access_level',
            from: old_access_level,
            to: member.human_access_labeled,
            expiry_from: old_expiry,
            expiry_to: member.expires_at,
            as: member.human_access_labeled,
            member_id: member.id
          }
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      end
    end
  end
end
