# frozen_string_literal: true

class ProjectImportScheduleWorker
  include ApplicationWorker

  data_consistency :delayed

  idempotent!
  deduplicate :until_executing, ttl: 5.minutes

  feature_category :source_code_management
  sidekiq_options retry: 1
  loggable_arguments 1 # For the job waiter key
  log_bulk_perform_async!

  def perform(project_id)
    ::Gitlab::Mirror.untrack_scheduling(project_id)

    return if Gitlab::Database.read_only?

    project = Project.with_route.with_import_state.with_namespace.find_by_id(project_id)

    with_context(project: project) do
      unless project&.import_state
        log_extra_metadata_on_done(:mirroring_skipped, "No import state found for #{project_id}")
        next
      end

      if project.mirror?
        project.import_state.schedule
      else
        # If the project does not support mirroring (missing license for example)
        # then we mark it as hard failed to exclude from UpdateAllMirrorWorker query
        if Feature.enabled?(:hard_failure_for_mirrors_without_license)
          # We cannot mark it as failed without changing the status to "scheduled"
          project.import_state.schedule

          project.import_state.set_max_retry_count
          project.import_state.mark_as_failed('Project mirroring is not supported')

          log_extra_metadata_on_done(:mirroring_skipped, 'Project does not support mirroring')
        end
      end
    end
  end
end
