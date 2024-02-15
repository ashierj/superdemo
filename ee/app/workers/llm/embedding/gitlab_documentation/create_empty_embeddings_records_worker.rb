# frozen_string_literal: true

module Llm
  module Embedding
    module GitlabDocumentation
      # DEPRECATED: Remove this in favor for CreateEmbeddingsRecordsWorker
      # see https://gitlab.com/gitlab-org/gitlab/-/issues/438337
      class CreateEmptyEmbeddingsRecordsWorker
        include ApplicationWorker
        include CronjobQueue # rubocop:disable Scalability/CronWorkerContext
        include Gitlab::ExclusiveLeaseHelpers
        include EmbeddingsWorkerContext

        idempotent!
        data_consistency :always # rubocop: disable SidekiqLoadBalancing/WorkerDataConsistency
        feature_category :duo_chat
        urgency :throttled
        sidekiq_options retry: 3

        def perform; end
      end
    end
  end
end
