# frozen_string_literal: true

module WorkItems
  module RolledupDates
    class UpdateParentRolledupDatesEventHandler
      include Gitlab::EventStore::Subscriber

      data_consistency :always
      feature_category :portfolio_management
      idempotent!

      UPDATE_TRIGGER_ATTRIBUTES = %w[
        start_date
        due_date
      ].freeze

      UPDATE_TRIGGER_WIDGETS = %w[
        start_and_due_date_widget
        rolledup_dates_widget
      ].freeze

      def self.can_handle_update?(event)
        UPDATE_TRIGGER_WIDGETS.any? { |widget| event.data.fetch(:updated_widgets, []).include?(widget) } ||
          UPDATE_TRIGGER_ATTRIBUTES.any? { |attribute| event.data.fetch(:updated_attributes, []).include?(attribute) }
      end

      def handle_event(event)
        parent = ::WorkItem.find_by_id(event.data[:id])&.work_item_parent
        return if parent.blank?

        ::WorkItems::Widgets::RolledupDatesService::HierarchyUpdateService
          .new(parent)
          .execute
      end
    end
  end
end
