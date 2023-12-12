# frozen_string_literal: true

module OpenAi
  class ClearConversationsWorker
    # We can only keep open ai data for 90 days
    # We run this as a cron job twice a day to clear out old conversation messages
    include ApplicationWorker

    # rubocop:disable Scalability/CronWorkerContext -- being removed
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    idempotent!
    feature_category :ai_abstraction_layer
    data_consistency :sticky
    deduplicate :until_executed, including_scheduled: true
    urgency :low

    # No-op. Being removed.
    def perform; end
  end
end
