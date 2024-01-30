# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class IncrementalWorker
      include ApplicationWorker

      # rubocop:disable Scalability/CronWorkerContext
      # This worker does not perform work scoped to a context
      include CronjobQueue
      # rubocop:enable Scalability/CronWorkerContext

      idempotent!

      data_consistency :always
      feature_category :value_stream_management

      def perform
        current_time = Time.current
        runtime_limiter = Gitlab::Metrics::RuntimeLimiter.new
        over_time = false

        loop do
          batch = Analytics::CycleAnalytics::Aggregation.load_batch(current_time)
          break if batch.empty?

          batch.each do |aggregation|
            Analytics::CycleAnalytics::AggregatorService.new(aggregation: aggregation, mode: :incremental,
              runtime_limiter: runtime_limiter).execute

            if runtime_limiter.over_time?
              over_time = true
              break
            end
          end

          break if over_time
        end
      end
    end
  end
end
