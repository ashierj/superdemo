# frozen_string_literal: true

module Vulnerabilities
  class ProcessTransferEventsWorker
    include Gitlab::EventStore::Subscriber

    idempotent!
    deduplicate :until_executing, including_scheduled: true
    data_consistency :always

    feature_category :vulnerability_management

    def handle_event(event)
      project_ids(event).each_slice(1_000) { |slice| bulk_schedule_worker(slice) }
    end

    private

    def bulk_schedule_worker(project_ids)
      # rubocop:disable Scalability/BulkPerformWithContext -- allow context omission
      Vulnerabilities::UpdateNamespaceIdsOfVulnerabilityReadsWorker.bulk_perform_async(project_ids.zip)
      # rubocop:enable Scalability/BulkPerformWithContext
    end

    def project_ids(event)
      case event
      when ::Projects::ProjectTransferedEvent
        vulnerable_project_ids(event.data[:project_id])
      when ::Groups::GroupTransferedEvent
        group = Group.find_by_id(event.data[:group_id])

        project_ids_for(group)
      end
    end

    def project_ids_for(group)
      return [] unless group

      subgroup_ids_for(group).flat_map do |sub_group_id|
        direct_project_ids_for(sub_group_id)
      end
    end

    def subgroup_ids_for(group)
      cursor = { current_id: group.id, depth: [group.id] }
      iterator = Gitlab::Database::NamespaceEachBatch.new(namespace_class: Group, cursor: cursor)

      group_ids = []

      iterator.each_batch(of: 100) { |ids| group_ids += ids }

      group_ids
    end

    def direct_project_ids_for(sub_group_id)
      project_ids = []

      Project.in_namespace(sub_group_id).each_batch(of: 100) do |batch|
        project_ids += vulnerable_project_ids(batch)
      end

      project_ids
    end

    def vulnerable_project_ids(batch)
      ProjectSetting.for_projects(batch)
                    .has_vulnerabilities
                    .pluck_primary_key
    end
  end
end
