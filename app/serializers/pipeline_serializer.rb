# frozen_string_literal: true

class PipelineSerializer < BaseSerializer
  include WithPagination
  entity PipelineDetailsEntity

  # rubocop: disable CodeReuse/ActiveRecord
  def represent(resource, opts = {})
    if resource.is_a?(ActiveRecord::Relation)
      # We don't want PipelineDetailsEntity to preload the job_artifacts_archive
      # because we do it with preloaded_relations in a more optimal way
      # if the given resource is a collection of multiple pipelines.
      opts[:preload_job_artifacts_archive] = false
      resource = resource.preload(preloaded_relations)
    end

    if paginated?
      resource = paginator.paginate(resource)
    end

    if opts.delete(:preload)
      resource = Gitlab::Ci::Pipeline::Preloader.preload!(resource)
    end

    super(resource, opts)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def represent_status(resource)
    return {} unless resource.present?

    data = represent(resource, { only: [{ details: [:status] }] })
    data.dig(:details, :status) || {}
  end

  def represent_stages(resource)
    return {} unless resource.present?

    data = represent(resource, { only: [{ details: [:stages] }], preload: true })
    data.dig(:details, :stages) || []
  end

  private

  def preloaded_relations
    [
      :latest_statuses_ordered_by_stage,
      :project,
      :stages,
      {
        failed_builds: %i(project metadata)
      },
      :retryable_builds,
      :cancelable_statuses,
      :trigger_requests,
      :manual_actions,
      :scheduled_actions,
      :artifacts,
      :user,
      {
        merge_request: {
          source_project: [:route, { namespace: :route }],
          target_project: [:route, { namespace: :route }]
        }
      },
      {
        pending_builds: :project,
        project: [:route, { namespace: :route }],
        artifacts: {
          project: [:route, { namespace: :route }],
          job_artifacts_archive: []
        }
      },
      { triggered_by_pipeline: [:project, :user] },
      { triggered_pipelines: [:project, :user] }
    ]
  end
end
