# frozen_string_literal: true

module Ci
  module Runners
    # Exports the runner usage for a given period (based on ClickHouse's ci_used_minutes_mv view)
    #
    class ExportUsageCsvService
      include ::Audit::Changes

      attr_reader :project_ids, :runner_type, :from_time, :to_time

      REPORT_ENTRY_LIMIT = 500 # Max number of projects listed in report

      # @param [User] current_user The user performing the reporting
      # @param [Symbol] runner_type The type of runners to report on. Defaults to nil, reporting on all runner types
      # @param [DateTime] from_time The start date of the period to examine. Defaults to start of last full month
      # @param [DateTime] to_time The end date of the period to examine. Defaults to end of month
      def initialize(current_user:, runner_type: nil, from_time: nil, to_time: nil)
        runner_type = Ci::Runner.runner_types[runner_type] if runner_type.is_a?(Symbol)

        @current_user = current_user
        @runner_type = runner_type
        @from_time = from_time || DateTime.current.prev_month.beginning_of_month
        @to_time = to_time || @from_time.end_of_month
      end

      def execute
        return db_not_configured unless ClickHouse::Client.configuration.database_configured?(:main)
        return insufficient_permissions unless Ability.allowed?(@current_user, :read_runner_usage)

        result = ClickHouse::Client.select(clickhouse_query, :main)
        csv_builder = CsvBuilder::SingleBatch.new(replace_with_project_paths(result), header_to_value_hash)
        csv_data = csv_builder.render(ExportCsv::BaseService::TARGET_FILESIZE)

        log_audit_event

        ServiceResponse.success(payload: { csv_data: csv_data, status: csv_builder.status })
      rescue StandardError => e
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
        ServiceResponse.error(message: 'Failed to generate export')
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
          'Project ID' => 'project_id',
          'Project path' => 'project_path',
          'Build count' => 'count_builds',
          'Total duration (minutes)' => 'total_duration_in_mins',
          'Total duration' => 'total_duration_human_readable'
        }
      end

      def clickhouse_query
        raw_query = <<~SQL.squish
          SELECT project_id,
                 countMerge(count_builds) AS count_builds,
                 sumSimpleState(total_duration) / 60000 AS total_duration_in_mins
          FROM   ci_used_minutes_mv
          WHERE  #{where_clause}
          GROUP BY project_id
          ORDER BY total_duration_in_mins DESC, project_id
          LIMIT #{REPORT_ENTRY_LIMIT};
        SQL

        ClickHouse::Client::Query.new(raw_query: raw_query, placeholders: placeholders.transform_values(&:to_s))
      end

      def where_clause
        <<~SQL
          #{'runner_type = {runner_type: UInt8} AND' if runner_type}
          finished_at_bucket >= {from_time: DateTime('UTC', 6)} AND
          finished_at_bucket < {to_time: DateTime('UTC', 6)}
        SQL
      end

      def placeholders
        placeholders = {
          runner_type: runner_type,
          from_time: format_datetime(@from_time),
          to_time: format_datetime(@to_time)
        }

        placeholders.compact
      end

      def format_datetime(datetime)
        datetime&.utc&.strftime('%Y-%m-%d %H:%M:%S')
      end

      def replace_with_project_paths(result)
        # rubocop: disable CodeReuse/ActiveRecord -- This is a ClickHouse query
        ids = result.pluck('project_id') # rubocop: disable Database/AvoidUsingPluckWithoutLimit -- The limit is already implemented in the ClickHouse query
        # rubocop: enable CodeReuse/ActiveRecord
        return result if ids.empty?

        projects = Project.inc_routes.id_in(ids).limit(REPORT_ENTRY_LIMIT).to_h { |p| [p.id, p.full_path] }

        # Annotate rows with project paths
        result.each do |row|
          row['project_path'] = projects[row['project_id']]
          row['total_duration_human_readable'] =
            ActiveSupport::Duration.build(row['total_duration_in_mins'] * 60).inspect
        end
      end

      def log_audit_event
        audit_context = {
          name: 'ci_runner_usage_export',
          author: @current_user || ::Gitlab::Audit::UnauthenticatedAuthor.new,
          scope: Gitlab::Audit::InstanceScope.new,
          target: Gitlab::Audit::InstanceScope.new,
          message: 'Generated CI runner usage report',
          additional_details: placeholders.compact
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      end
    end
  end
end
