# frozen_string_literal: true

class ElasticRemoveExpiredNamespaceSubscriptionsFromIndexCronWorker
  include ApplicationWorker
  prepend ::Geo::SkipSecondary
  prepend Elastic::IndexingControl

  data_consistency :always

  include Gitlab::ExclusiveLeaseHelpers
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- This is a cron job

  feature_category :global_search
  idempotent!

  def perform
    return false unless ::Gitlab::Saas.feature_available?(:advanced_search)

    namespaces_removed = ::Search::Elastic::DestroyExpiredSubscriptionService.new.execute

    log_extra_metadata_on_done(:namespaces_removed_count, namespaces_removed)
  end
end
