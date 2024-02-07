# frozen_string_literal: true

module EE
  module WorkItems
    module CreateService
      extend ::Gitlab::Utils::Override

      private

      override :iid_param_allowed?
      def iid_param_allowed?
        sync_work_item? || super
      end

      override :filter_timestamp_params
      def filter_timestamp_params
        return if sync_work_item?

        super
      end

      override :skip_system_notes?
      def skip_system_notes?
        return true if sync_work_item?

        super
      end

      override :after_commit_tasks
      def after_commit_tasks(user, work_item)
        return if sync_work_item?

        super
      end

      def sync_work_item?
        extra_params&.fetch(:synced_work_item, false)
      end
    end
  end
end
