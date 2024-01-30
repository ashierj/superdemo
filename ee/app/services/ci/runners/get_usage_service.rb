# frozen_string_literal: true

module Ci
  module Runners
    class GetUsageService
      include Gitlab::Utils::StrongMemoize
      def initialize(current_user, runner_type:, from_date:, to_date:, max_runners_count:)
        @current_user = current_user
        @runner_type = Ci::Runner.runner_types[runner_type]
        @from_date = from_date
        @to_date = to_date
        @max_runners_count = max_runners_count
      end

      def execute
        unless ::Gitlab::ClickHouse.configured?
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

      attr_reader :runner_type, :from_date, :to_date, :max_runners_count

      def clickhouse_query
        raw_query = <<~SQL.squish
          WITH top_runners AS
            (
              SELECT runner_id
              FROM ci_used_minutes_by_runner_daily
              WHERE #{where_conditions}
              GROUP BY runner_id
              ORDER BY sumSimpleState(total_duration) DESC
              LIMIT {max_runners_count: UInt64}
            )
          SELECT
            IF(ci_used_minutes_by_runner_daily.runner_id IN top_runners, ci_used_minutes_by_runner_daily.runner_id, NULL)
              AS runner_id,
            countMerge(count_builds) AS count_builds,
            toUInt64(sumSimpleState(total_duration) / 60000) AS total_duration_in_mins
          FROM ci_used_minutes_by_runner_daily
          WHERE #{where_conditions}
          GROUP BY runner_id
          ORDER BY (runner_id IS NULL), total_duration_in_mins DESC, runner_id ASC
        SQL

        ClickHouse::Client::Query.new(raw_query: raw_query, placeholders: placeholders)
      end

      def placeholders
        placeholders = {
          runner_type: runner_type,
          from_date: format_date(from_date),
          to_date: format_date(to_date + 1), # Include jobs until the end of the day
          max_runners_count: max_runners_count
        }

        placeholders.compact
      end

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
