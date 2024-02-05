# frozen_string_literal: true

module Sbom
  class ProcessTransferEventsWorker
    include Gitlab::EventStore::Subscriber

    idempotent!
    deduplicate :until_executing, including_scheduled: true
    data_consistency :always

    feature_category :dependency_management

    def handle_event(event)
      args = project_ids(event).zip

      ::Sbom::SyncProjectTraversalIdsWorker.perform_bulk(args)
    end

    private

    def project_ids(event)
      case event
      when ::Projects::ProjectTransferedEvent
        project_id = event.data[:project_id]

        return [] unless Sbom::Occurrence.by_project_ids(project_id).exists?

        [project_id]
      when ::Groups::GroupTransferedEvent
        group = Group.find_by_id(event.data[:group_id])

        return [] unless group

        # rubocop:disable CodeReuse/ActiveRecord -- Does not work outside this context.
        exists_subquery = Sbom::Occurrence.where(
          "#{Sbom::Occurrence.quoted_table_name}.project_id = #{Project.quoted_table_name}.id")
        # rubocop:enable CodeReuse/ActiveRecord

        group
          .all_project_ids
          .where_exists(exists_subquery)
          .pluck_primary_key
      end
    end
  end
end
