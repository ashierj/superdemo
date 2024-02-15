# frozen_string_literal: true

# !!! WARNING !!!
# We keep it for compatibility during 16.9. Planned for removal in future releases.
# Starting 16.10, apply all changes to Cloud::SyncServiceTokenWorker instead.
# Refer to https://gitlab.com/groups/gitlab-org/-/epics/12544.
module Ai
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
