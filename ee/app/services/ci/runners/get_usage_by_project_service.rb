# frozen_string_literal: true

module Ci
  module Runners
    class GetUsageByProjectService
      include Gitlab::Utils::StrongMemoize
      def initialize(current_user, runner_type:, from_date:, to_date:, max_project_count:, group_by_columns: [])
        @current_user = current_user
        @runner_type = Ci::Runner.runner_types[runner_type]
        @from_date = from_date
        @to_date = to_date
        @max_project_count = max_project_count
        @group_by_columns = group_by_columns
      end

      def execute
        unless ::ClickHouse::Client.database_configured?(:main)
          return ServiceResponse.error(message: 'ClickHouse database is not configured',
            reason: :db_not_configured)
        end

        unless Ability.allowed?(@current_user, :read_runner_usage)
          return ServiceResponse.error(message: 'Insufficient permissions',
            reason: :insufficient_permissions)
        end

        data = ClickHouse::Client.select(clickhouse_query, :main)
        ServiceResponse.success(payload: data)
      end

      private

      attr_reader :runner_type, :from_date, :to_date, :group_by_columns, :max_project_count

      def clickhouse_query
        grouping_columns = ['grouped_project_id', *group_by_columns].join(', ')
        raw_query = <<~SQL.squish
          WITH top_projects AS
            (
              SELECT project_id
              FROM ci_used_minutes_mv
              WHERE #{where_conditions}
              GROUP BY project_id
              ORDER BY sumSimpleState(total_duration) DESC
              LIMIT {max_project_count: UInt64}
            )
          SELECT IF(project_id IN top_projects, project_id, NULL) AS grouped_project_id, #{select_list}
          FROM ci_used_minutes_mv
          WHERE #{where_conditions}
          GROUP BY #{grouping_columns}
          ORDER BY (grouped_project_id IS NULL), #{order_list}
        SQL

        ClickHouse::Client::Query.new(raw_query: raw_query, placeholders: placeholders)
      end

      def placeholders
        placeholders = {
          runner_type: runner_type,
          from_date: format_date(from_date),
          to_date: format_date(to_date + 1), # Include jobs until the end of the day
          max_project_count: max_project_count
        }

        placeholders.compact
      end

      def select_list
        [
          *group_by_columns,
          'countMerge(count_builds) AS count_builds',
          'toUInt64(sumSimpleState(total_duration) / 60000) AS total_duration_in_mins'
        ].join(', ')
      end
      strong_memoize_attr :select_list

      def order_list
        [
          'total_duration_in_mins DESC',
          'grouped_project_id ASC',
          *group_by_columns.map { |column| "#{column} ASC" }
        ].join(', ')
      end
      strong_memoize_attr :order_list

      def where_conditions
        <<~SQL
          #{'runner_type = {runner_type: UInt8} AND' if runner_type}
          finished_at_bucket >= {from_date: DateTime('UTC', 6)} AND
          finished_at_bucket < {to_date: DateTime('UTC', 6)}
        SQL
      end
      strong_memoize_attr :where_conditions

      def format_date(date)
        date.strftime('%Y-%m-%d %H:%M:%S')
      end
    end
  end
end
