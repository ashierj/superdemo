# frozen_string_literal: true

module ClickHouse
  module DataIngestion
    class CiFinishedBuildsSyncService
      include Gitlab::ExclusiveLeaseHelpers
      include Gitlab::Utils::StrongMemoize

      # the job is scheduled every 3 minutes and we will allow maximum 6 minutes runtime
      # we must allow a minimum of 2 minutes + 15 seconds PG timeout + 1 minute for the various CH Gitlab::HTTP timeouts
      MAX_TTL = 6.minutes.to_i
      MAX_RUNTIME = 120.seconds
      BUILDS_BATCH_SIZE = 500
      INSERT_BATCH_SIZE = 5000
      BUILD_ID_PARTITIONS = 100

      def initialize(worker_index: 0, total_workers: 1)
        @runtime_limiter = Analytics::CycleAnalytics::RuntimeLimiter.new(MAX_RUNTIME)
        @worker_index = worker_index
        @total_workers = total_workers
      end

      def execute
        @total_record_count = 0

        unless enabled?
          return ServiceResponse.error(
            message: 'Feature ci_data_ingestion_to_click_house is disabled',
            reason: :disabled
          )
        end

        unless ClickHouse::Client.configuration.databases[:main].present?
          return ServiceResponse.error(message: 'ClickHouse database is not configured', reason: :db_not_configured)
        end

        # Prevent parallel jobs
        in_lock("#{self.class.name.underscore}/worker/#{@worker_index}", ttl: MAX_TTL, retries: 0) do
          ::Gitlab::Database::LoadBalancing::Session.without_sticky_writes do
            report = insert_new_finished_builds

            ServiceResponse.success(payload: report)
          end
        end
      rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError => e
        # Skip retrying, just let the next worker to start after a few minutes
        ServiceResponse.error(message: e.message, reason: :skipped)
      end

      private

      def insert_new_finished_builds
        # Read batches of BUILDS_BATCH_SIZE until the timeout in MAX_RUNTIME is reached
        # We can expect a single worker to process around 3.4M builds/hour with a single worker,
        # and a bit over 9M builds/hours with three workers (measured in staging).
        loop do
          @processed_record_ids = []

          CsvBuilder::Gzip.new(process_batch, CSV_MAPPING).render do |tempfile|
            File.open(tempfile.path) do |f|
              ClickHouse::Client.insert_csv(INSERT_FINISHED_BUILDS_QUERY, f, :main)
            end
          end

          Ci::FinishedBuildChSyncEvent.primary_key_in(@processed_record_ids).update_all(processed: true)
          @processed_record_ids = []

          unless continue?
            return {
              records_inserted: @total_record_count,
              reached_end_of_table: !@more_records
            }
          end
        end
      end

      BUILD_FIELD_NAMES = %i[id project_id pipeline_id status runner_id].freeze
      BUILD_EPOCH_FIELD_NAMES = %i[created_at queued_at started_at finished_at].freeze
      RUNNER_FIELD_NAMES = %i[run_untagged type].freeze
      RUNNER_MANAGER_FIELD_NAMES = %i[system_xid version revision platform architecture].freeze

      CSV_MAPPING = {
        **BUILD_FIELD_NAMES.index_with { |n| n },
        **BUILD_EPOCH_FIELD_NAMES.index_with { |n| :"casted_#{n}" },
        **RUNNER_FIELD_NAMES.map { |n| :"runner_#{n}" }.index_with { |n| n },
        **RUNNER_MANAGER_FIELD_NAMES.map { |n| :"runner_manager_#{n}" }.index_with { |n| n }
      }.freeze

      INSERT_FINISHED_BUILDS_QUERY = <<~SQL.squish
        INSERT INTO ci_finished_builds (#{CSV_MAPPING.keys.join(', ')})
        SETTINGS async_insert=1, wait_for_async_insert=1 FORMAT CSV
      SQL

      def enabled?
        Feature.enabled?(:ci_data_ingestion_to_click_house)
      end

      def finished_build_projections
        [
          *BUILD_FIELD_NAMES,
          *BUILD_EPOCH_FIELD_NAMES.map { |n| "EXTRACT(epoch FROM #{::Ci::Build.table_name}.#{n}) AS casted_#{n}" },
          "#{::Ci::Runner.table_name}.run_untagged AS runner_run_untagged",
          "#{::Ci::Runner.table_name}.runner_type AS runner_type",
          *RUNNER_MANAGER_FIELD_NAMES.map { |n| "#{::Ci::RunnerManager.table_name}.#{n} AS runner_manager_#{n}" }
        ]
      end
      strong_memoize_attr :finished_build_projections

      def continue?
        @more_records && !@runtime_limiter.over_time?
      end

      def process_batch
        Enumerator.new do |yielder|
          @more_records = false

          total_records_yielded = 0

          keyset_iterator_scope.each_batch(of: BUILDS_BATCH_SIZE) do |events_batch|
            build_ids = events_batch.pluck(:build_id) # rubocop: disable CodeReuse/ActiveRecord
            Ci::Build.id_in(build_ids)
              .left_outer_joins(:runner, :runner_manager)
              .select(:finished_at, *finished_build_projections)
              .each do |build|
              yielder << build
              @processed_record_ids << build.id
              total_records_yielded += 1
            end

            @more_records = build_ids.count == BUILDS_BATCH_SIZE
            break unless continue? && total_records_yielded < INSERT_BATCH_SIZE
          end

          @total_record_count += @processed_record_ids.count
        end
      end

      def keyset_iterator_scope
        lower_bound = (@worker_index * BUILD_ID_PARTITIONS / @total_workers).to_i
        upper_bound = ((@worker_index + 1) * BUILD_ID_PARTITIONS / @total_workers).to_i

        table_name = Ci::FinishedBuildChSyncEvent.quoted_table_name
        array_scope = Ci::FinishedBuildChSyncEvent.select(:build_id_partition)
          .from("generate_series(#{lower_bound}, #{upper_bound}) as #{table_name}(build_id_partition)") # rubocop: disable CodeReuse/ActiveRecord

        opts = {
          in_operator_optimization_options: {
            array_scope: array_scope,
            array_mapping_scope: ->(id_expression) do
              Ci::FinishedBuildChSyncEvent
                .where(Arel.sql("(build_id % #{BUILD_ID_PARTITIONS})") # rubocop: disable CodeReuse/ActiveRecord
                  .eq(id_expression))
            end
          }
        }

        Gitlab::Pagination::Keyset::Iterator.new(scope: Ci::FinishedBuildChSyncEvent.pending.order_by_build_id, **opts)
      end
    end
  end
end
