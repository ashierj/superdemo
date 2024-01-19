# frozen_string_literal: true

module EE
  module WorkItems
    module CreateService
      extend ::Gitlab::Utils::Override

      private

      override :iid_param_allowed?
      def iid_param_allowed?
        # Used when creating a new epic with a synced work item
        extra_params&.fetch(:synced_work_item, false) || super
      end

      override :filter_timestamp_params
      def filter_timestamp_params
        return if extra_params&.fetch(:synced_work_item, false)

        super
      end
    end
  end
end
