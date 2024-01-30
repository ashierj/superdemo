# frozen_string_literal: true

# !!! WARNING !!!
# We keep it for compatibility. Planned for removal in 16.11.
# Starting 16.10, apply all changes to Cloud::SyncServiceTokenWorker instead.
# Refer to https://gitlab.com/groups/gitlab-org/-/epics/12544 to track the status.
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
      result = ::CloudConnector::SyncCloudConnectorAccessService.new.execute

      log_extra_metadata_on_done(:error_message, result[:message]) unless result.success?
    end
  end
end
