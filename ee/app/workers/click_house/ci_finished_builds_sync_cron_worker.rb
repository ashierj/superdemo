# frozen_string_literal: true

module ClickHouse
  class CiFinishedBuildsSyncCronWorker
    include ApplicationWorker

    idempotent!
    queue_namespace :cronjob
    data_consistency :delayed
    worker_has_external_dependencies! # the worker interacts with a ClickHouse database
    feature_category :runner_fleet

    def perform(worker_index = 0, total_workers = 1)
      response = ::ClickHouse::DataIngestion::CiFinishedBuildsSyncService.new(
        worker_index: worker_index, total_workers: total_workers
      ).execute

      result = response.success? ? response.payload : response.deconstruct_keys(%i[message reason])
      log_extra_metadata_on_done(:result, result)
    end
  end
end
