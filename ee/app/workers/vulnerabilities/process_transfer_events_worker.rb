# frozen_string_literal: true

module Vulnerabilities
  class ProcessTransferEventsWorker
    include Gitlab::EventStore::Subscriber

    idempotent!
    deduplicate :until_executing, including_scheduled: true
    data_consistency :always

    feature_category :vulnerability_management

    def handle_event(event)
      bulk_arguments = ProjectSetting
        .for_projects(project_ids(event))
        .has_vulnerabilities
        .pluck_primary_key
        .zip

      Vulnerabilities::UpdateNamespaceIdsOfVulnerabilityReadsWorker.perform_bulk(bulk_arguments)
    end

    private

    def project_ids(event)
      case event
      when ::Projects::ProjectTransferedEvent
        [event.data[:project_id]]
      when ::Groups::GroupTransferedEvent
        group = Group.find_by_id(event.data[:group_id])

        return [] unless group

        group.all_project_ids
      end
    end
  end
end
