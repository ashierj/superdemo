# frozen_string_literal: true

module WorkItems
  module Widgets
    class RolledupDates < Base
      delegate :due_date,
        :due_date_fixed,
        :due_date_is_fixed,
        :due_date_sourcing_work_item,
        :due_date_sourcing_milestone,
        :start_date,
        :start_date_fixed,
        :start_date_is_fixed,
        :start_date_sourcing_work_item,
        :start_date_sourcing_milestone,
        to: :dates_source,
        allow_nil: true

      alias_method :due_date_is_fixed?, :due_date_is_fixed
      alias_method :start_date_is_fixed?, :start_date_is_fixed

      def dates_source
        work_item&.dates_source
      end

      def self.sync_params
        [:start_date_fixed, :start_date_is_fixed, :due_date_fixed, :due_date_is_fixed]
      end
    end
  end
end
