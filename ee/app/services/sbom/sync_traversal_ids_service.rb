# frozen_string_literal: true

module Sbom
  class SyncTraversalIdsService
    include Gitlab::ExclusiveLeaseHelpers

    BATCH_SIZE = 100
    LEASE_KEY = 'sync_sbom_occurrences_traversal_ids'
    LEASE_TTL = 5.minutes
    LEASE_TRY_AFTER = 3.seconds

    def self.execute(project_id)
      new(project_id).execute
    end

    def initialize(project_id)
      @project_id = project_id
    end

    def execute
      return unless project

      in_lock(LEASE_KEY, ttl: LEASE_TTL, sleep_sec: LEASE_TRY_AFTER) { update_sbom_occurrences }
    end

    private

    attr_reader :project_id

    def project
      @project ||= Project.find_by_id(project_id)
    end

    def update_sbom_occurrences
      project.sbom_occurrences.each_batch(of: BATCH_SIZE) do |batch|
        batch.update_all(traversal_ids: project.namespace.traversal_ids)
      end
    end
  end
end
