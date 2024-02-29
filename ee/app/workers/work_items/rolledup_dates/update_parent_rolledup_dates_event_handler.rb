# frozen_string_literal: true

module WorkItems
  module RolledupDates
    class UpdateParentRolledupDatesEventHandler
      include Gitlab::EventStore::Subscriber

      data_consistency :always
      feature_category :portfolio_management
      idempotent!

      def handle_event(event)
        parent = ::WorkItem.find(event.data[:id])&.work_item_parent
        return if parent.blank?

        ::WorkItems::Widgets::RolledupDatesService::HierarchyUpdateService
          .new(parent)
          .execute
      end
    end
  end
end
