# frozen_string_literal: true

module WorkItems
  module Widgets
    module RolledupDatesService
      class BaseService < ::WorkItems::Widgets::BaseService
        private

        def handle_rolledup_dates_change(params)
          return unless params.present? && rolledup_dates_available? && has_permission?(:set_work_item_metadata)

          (work_item.dates_source || work_item.build_dates_source).then do |dates_source|
            dates_source.update(AttributesBuilder.build(work_item, params))
          end
        end

        def rolledup_dates_available?
          ::Feature.enabled?(:work_items_rolledup_dates, work_item.resource_parent)
        end
      end
    end
  end
end
