# frozen_string_literal: true

module WorkItems
  module Widgets
    module RolledupDatesService
      class BaseService < ::WorkItems::Widgets::BaseService
        private

        def handle_rolledup_dates_change(params)
          return unless params.present? && can_set_rolledup_dates?(params)

          (work_item.dates_source || work_item.build_dates_source).then do |dates_source|
            dates_source.update(AttributesBuilder.build(work_item, params))
          end
        end

        def can_set_rolledup_dates?(params)
          return true if params.fetch(:synced_work_item, false)

          ::Feature.enabled?(:work_items_rolledup_dates, work_item.resource_parent) &&
            has_permission?(:set_work_item_metadata)
        end
      end
    end
  end
end
