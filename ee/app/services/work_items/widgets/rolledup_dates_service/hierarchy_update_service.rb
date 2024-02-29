# frozen_string_literal: true

module WorkItems
  module Widgets
    module RolledupDatesService
      class HierarchyUpdateService
        def initialize(work_item)
          @work_item = work_item
        end

        def execute
          return if work_item.blank?
          return unless ::Feature.enabled?(:work_items_rolledup_dates, work_item.resource_parent)

          work_item.build_dates_source if work_item.dates_source.blank?

          attributes = {}

          unless work_item.dates_source.due_date_is_fixed?
            maximum_due_date_attributes = finder.maximum_due_date.first&.attributes
            attributes.merge!(maximum_due_date_attributes) if maximum_due_date_attributes.present?
          end

          unless work_item.dates_source.start_date_is_fixed?
            minimum_start_date_attributes = finder.minimum_start_date.first&.attributes
            attributes.merge!(minimum_start_date_attributes) if minimum_start_date_attributes.present?
          end

          work_item.dates_source.update!(attributes.except('issue_id')) if attributes.present?

          update_parent
        end

        private

        attr_reader :work_item

        def finder
          @finder ||= WorkItems::Widgets::RolledupDatesFinder.new(work_item)
        end

        def update_parent
          parent = work_item.work_item_parent
          return if parent.blank?

          ::WorkItems::RolledupDates::UpdateRolledupDatesWorker.perform_async(parent.id)
        end
      end
    end
  end
end
