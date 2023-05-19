# frozen_string_literal: true

module Llm
  module TanukiBot
    class RemovePreviousRecordsWorker
      include ApplicationWorker
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

      idempotent!
      data_consistency :always # rubocop: disable SidekiqLoadBalancing/WorkerDataConsistency
      feature_category :global_search
      urgency :throttled

      BATCH_SIZE = 1000
      TIME_LIMIT = 3.minutes

      def perform
        return unless Feature.enabled?(:openai_experimentation)
        return unless Feature.enabled?(:tanuki_bot)
        return unless Feature.enabled?(:tanuki_bot_indexing)
        return unless ::License.feature_available?(:ai_tanuki_bot)

        ::Embedding::TanukiBotMvc.previous.limit(BATCH_SIZE).delete_all

        return unless ::Embedding::TanukiBotMvc.previous.exists?

        Llm::TanukiBot::RemovePreviousRecordsWorker.perform_in(10.seconds)
      end
    end
  end
end
