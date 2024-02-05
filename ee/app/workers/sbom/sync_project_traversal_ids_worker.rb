# frozen_string_literal: true

module Sbom
  class SyncProjectTraversalIdsWorker
    include ApplicationWorker

    idempotent!
    deduplicate :until_executing, including_scheduled: true
    # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency -- This worker exclusively performs writes.
    data_consistency :always
    # rubocop:enable SidekiqLoadBalancing/WorkerDataConsistency

    feature_category :dependency_management

    def perform(project_id)
      ::Sbom::SyncTraversalIdsService.execute(project_id)
    end
  end
end
