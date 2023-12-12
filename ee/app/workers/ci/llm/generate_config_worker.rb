# frozen_string_literal: true

module Ci
  module Llm
    class GenerateConfigWorker
      include ApplicationWorker
      include ::Gitlab::ExclusiveLeaseHelpers

      idempotent!
      deduplicate :until_executed, including_scheduled: true
      data_consistency :delayed
      feature_category :pipeline_composition
      urgency :high
      sidekiq_options retry: 3

      # No-op. Being removed.
      def perform(ai_message_id); end
    end
  end
end
