# frozen_string_literal: true

module CloudConnector
  class SyncServiceTokenWorker
    include ApplicationWorker

    data_consistency :sticky

    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- Does not perform work scoped to a context

    idempotent!

    sidekiq_options retry: 3

    worker_has_external_dependencies!

    feature_category :cloud_connector

    def perform
      return unless ::Feature.enabled?(:use_sync_service_token_worker)

      result = ::CloudConnector::SyncCloudConnectorAccessService.new.execute

      log_extra_metadata_on_done(:error_message, result[:message]) unless result.success?
    end
  end
end
