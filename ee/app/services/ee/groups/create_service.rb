# frozen_string_literal: true

module EE
  module Groups
    module CreateService
      extend ::Gitlab::Utils::Override

      AUDIT_EVENT_TYPE = 'group_created'
      AUDIT_EVENT_MESSAGE = 'Added group'

      private

      override :after_build_hook
      def after_build_hook
        super

        # Repository size limit comes as MB from the view
        limit = params.delete(:repository_size_limit)
        group.repository_size_limit = ::Gitlab::Utils.try_megabytes_to_bytes(limit) if limit
      end

      override :after_successful_creation_hook
      def after_successful_creation_hook
        super

        log_audit_event
      end

      override :remove_unallowed_params
      def remove_unallowed_params
        unless current_user&.admin?
          params.delete(:shared_runners_minutes_limit)
          params.delete(:extra_shared_runners_minutes_limit)
        end

        params.delete(:repository_size_limit) unless current_user&.can_admin_all_resources?

        super
      end

      def log_audit_event
        audit_context = {
          name: AUDIT_EVENT_TYPE,
          author: current_user,
          scope: group,
          target: group,
          message: AUDIT_EVENT_MESSAGE,
          target_details: group.full_path
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      end
    end
  end
end
