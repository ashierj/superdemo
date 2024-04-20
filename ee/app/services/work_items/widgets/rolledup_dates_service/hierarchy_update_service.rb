# frozen_string_literal: true

module WorkItems
  module Widgets
    module RolledupDatesService
      class HierarchyUpdateService
        def initialize(work_item, previous_work_item_parent_id = nil)
          @work_item = work_item
          @previous_work_item_parent_id = previous_work_item_parent_id
        end

        def execute
          return if work_item.blank?
          return unless ::Feature.enabled?(:work_items_rolledup_dates, work_item.resource_parent)

          work_item.build_dates_source if work_item.dates_source.blank?

          attributes = attributes_for(:due_date).merge(attributes_for(:start_date))
          work_item.dates_source.update!(attributes.except('issue_id')) if attributes.present?

          update_parent
        end

        private

        attr_reader :work_item

        def attributes_for(field)
          return {} if work_item.dates_source.read_attribute(:"#{field}_is_fixed")

          finder.attributes_for(field).presence || {
            field => nil,
            "#{field}_sourcing_milestone_id": nil,
            "#{field}_sourcing_work_item_id": nil
          }
        end

        def finder
          @finder ||= WorkItems::Widgets::RolledupDatesFinder.new(work_item)
        end

        def update_parent
          parent_id = @previous_work_item_parent_id || work_item.work_item_parent&.id
          return if parent_id.blank?

          ::WorkItems::RolledupDates::UpdateRolledupDatesWorker.perform_async(parent_id)
        end
      end
    end
  end
end
