# frozen_string_literal: true

module Ci
  module Runners
    # Generates a CSV report containing the runner usage for a given period
    #   (based on ClickHouse's ci_used_minutes_mv view)
    #
    class GenerateUsageCsvService
      attr_reader :project_ids, :runner_type, :from_date, :to_date

      DEFAULT_PROJECT_COUNT = 1_000
      MAX_PROJECT_COUNT = 1_000
      OTHER_PROJECTS_NAME = '<Other projects>'

      # @param [User] current_user The user performing the reporting
      # @param [Symbol] runner_type The type of runners to report on. Defaults to nil, reporting on all runner types
      # @param [Date] from_date The start date of the period to examine. Defaults to start of last full month
      # @param [Date] to_date The end date of the period to examine. Defaults to end of month
      # @param [Integer] max_project_count The maximum number of projects in the report. All others will be folded
      #   into an 'Other projects' entry. Defaults to 1000
      def initialize(current_user:, runner_type: nil, from_date: nil, to_date: nil, max_project_count: nil)
        runner_type = Ci::Runner.runner_types[runner_type] if runner_type.is_a?(Symbol)

        @current_user = current_user
        @runner_type = runner_type
        @from_date = from_date || Date.current.prev_month.beginning_of_month
        @to_date = to_date || @from_date.end_of_month
        @max_project_count = [MAX_PROJECT_COUNT, max_project_count || DEFAULT_PROJECT_COUNT].min
      end

      def execute
        return db_not_configured unless ClickHouse::Client.database_configured?(:main)
        return insufficient_permissions unless Ability.allowed?(@current_user, :read_runner_usage)

        result = ClickHouse::Client.select(clickhouse_query, :main)
        rows = transform_rows(result)
        csv_builder = CsvBuilder::SingleBatch.new(rows, header_to_value_hash)
        csv_data = csv_builder.render(ExportCsv::BaseService::TARGET_FILESIZE)
        export_status = csv_builder.status

        others_row_created = rows.last.present? && rows.last['grouped_project_id'].nil?
        if others_row_created
          # Do not report <Other projects> row
          export_status[:rows_written] = export_status[:rows_written] - 1
          export_status[:rows_expected] = export_status[:rows_expected] - 1
        end

        ServiceResponse.success(payload: { csv_data: csv_data, status: export_status })
      rescue StandardError => e
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
        ServiceResponse.error(message: 'Failed to generate export', reason: :clickhouse_error)
      end

      private

      def db_not_configured
        ServiceResponse.error(message: 'ClickHouse database is not configured', reason: :db_not_configured)
      end

      def insufficient_permissions
        ServiceResponse.error(message: 'Insufficient permissions to generate export', reason: :insufficient_permissions)
      end

      def header_to_value_hash
        {
          'Project ID' => 'grouped_project_id',
          'Project path' => 'project_path',
          'Build count' => 'count_builds',
          'Total duration (minutes)' => 'total_duration_in_mins',
          'Total duration' => 'total_duration_human_readable'
        }
      end

      def clickhouse_query
        # This query computes the top-used projects, and performs a union to add the aggregates
        # for the projects not in that list
        raw_query = <<~SQL.squish
          WITH top_projects AS
            (
                SELECT
                  project_id,
                  countMerge(count_builds) AS count_builds,
                  sumSimpleState(total_duration) / 60000 AS total_duration_in_mins
                FROM ci_used_minutes_mv
                WHERE #{where_clause}
                GROUP BY project_id
                ORDER BY
                  total_duration_in_mins DESC,
                  project_id ASC
                LIMIT {max_project_count: UInt64}
            )
          SELECT project_id AS grouped_project_id, count_builds, total_duration_in_mins
          FROM top_projects
          UNION ALL
          SELECT
            NULL AS grouped_project_id,
            countMerge(count_builds) AS count_builds,
            sumSimpleState(total_duration) / 60000 AS total_duration_in_mins
          FROM ci_used_minutes_mv
          WHERE #{where_clause} AND project_id NOT IN (SELECT project_id FROM top_projects)
        SQL

        ClickHouse::Client::Query.new(raw_query: raw_query, placeholders: placeholders)
      end

      def where_clause
        <<~SQL
          #{'runner_type = {runner_type: UInt8} AND' if runner_type}
          finished_at_bucket >= {from_date: DateTime('UTC', 6)} AND
          finished_at_bucket < {to_date: DateTime('UTC', 6)}
        SQL
      end

      def placeholders
        placeholders = {
          runner_type: runner_type,
          from_date: format_date(@from_date),
          to_date: format_date(@to_date + 1), # Include jobs until the end of the day
          max_project_count: @max_project_count
        }

        placeholders.compact
      end

      def format_date(date)
        date.strftime('%Y-%m-%d %H:%M:%S')
      end

      def transform_rows(result)
        # rubocop: disable CodeReuse/ActiveRecord -- This is a ClickHouse query
        ids = result.pluck('grouped_project_id') # rubocop: disable Database/AvoidUsingPluckWithoutLimit -- The limit is already implemented in the ClickHouse query
        # rubocop: enable CodeReuse/ActiveRecord
        return result if ids.empty?

        projects = Project.inc_routes.id_in(ids).to_h { |p| [p.id, p.full_path] }
        projects[nil] = OTHER_PROJECTS_NAME

        # Annotate rows with project paths and human-readable durations
        result.each do |row|
          row['project_path'] = projects[row['grouped_project_id']&.to_i]
          row['total_duration_human_readable'] =
            ActiveSupport::Duration.build(row['total_duration_in_mins'] * 60).inspect
        end

        # Perform special treatment for <Other projects> entry (if existing), moving it to the end of the list
        other_projects_row = result.find { |row| row['grouped_project_id'].nil? }
        if other_projects_row
          result.reject! { |row| row['grouped_project_id'].nil? }
          result << other_projects_row if other_projects_row['count_builds'] > 0
        end

        result
      end
    end
  end
end
