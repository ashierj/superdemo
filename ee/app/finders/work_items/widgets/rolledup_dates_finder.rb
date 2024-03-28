# frozen_string_literal: true

module WorkItems
  module Widgets
    class RolledupDatesFinder
      FIELD_ORDER_DIRECTION = { start_date: :asc, due_date: :desc }.freeze

      # rubocop: disable CodeReuse/ActiveRecord -- Complex query building, this won't be reused anywhere else,
      # therefore, moving it to the Model will only increase the indirection.
      def initialize(work_item)
        @work_item = work_item
      end

      def minimum_start_date
        build_query_for(:start_date)
      end

      def maximum_due_date
        build_query_for(:due_date)
      end

      def attributes_for(field)
        raise ArgumentError, "unknown field '#{field}'" unless FIELD_ORDER_DIRECTION.key?(field)

        (build_query_for(field).first&.attributes || {}).with_indifferent_access
      end

      private

      attr_reader :work_item

      def build_query_for(field)
        WorkItems::DatesSource
          .with(issues_cte.to_arel)
          .from_union(milestones_date(field), children_date_source(field), children_date(field))
          .where.not(field => nil)
          .select(field, :"#{field}_sourcing_milestone_id", :"#{field}_sourcing_work_item_id")
          .order(field => FIELD_ORDER_DIRECTION[field])
          .limit(1)
      end

      def milestones_date(field)
        WorkItem.joins(:milestone).select(
          ::Milestone.arel_table[field].as(field.to_s),
          ::Milestone.arel_table[:id].as("#{field}_sourcing_milestone_id"),
          "NULL AS #{field}_sourcing_work_item_id")
      end

      def children_date_source(field)
        WorkItem.joins(:dates_source).select(
          WorkItems::DatesSource.arel_table[field].as(field.to_s),
          "NULL AS #{field}_sourcing_milestone_id",
          WorkItems::DatesSource.arel_table[:issue_id].as("#{field}_sourcing_work_item_id"))
      end

      # Once we migrate all the issues.start/due dates to work_item_dates_source
      # we won't need this anymore.
      def children_date(field)
        WorkItem.select(
          WorkItem.arel_table[field].as(field.to_s),
          "NULL AS #{field}_sourcing_milestone_id",
          WorkItem.arel_table[:id].as("#{field}_sourcing_work_item_id"))
      end

      def issues_cte
        @issues_cte ||= Gitlab::SQL::CTE.new(:issues, work_item.work_item_children.select(
          WorkItem.arel_table[:milestone_id].as("milestone_id"),
          WorkItem.arel_table[:start_date].as("start_date"),
          WorkItem.arel_table[:due_date].as("due_date"),
          WorkItem.arel_table[:id].as("id")))
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
