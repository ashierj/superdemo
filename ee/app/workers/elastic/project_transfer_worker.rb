# frozen_string_literal: true

module Elastic
  class ProjectTransferWorker
    include ApplicationWorker
    prepend IndexingControl
    prepend ::Geo::SkipSecondary

    data_consistency :delayed

    feature_category :global_search
    idempotent!
    urgency :throttled

    def perform(project_id, old_namespace_id, new_namespace_id)
      project = Project.find(project_id)
      should_invalidate_elasticsearch_indexes_cache = should_invalidate_elasticsearch_indexes_cache?(
        old_namespace_id, new_namespace_id
      )

      if should_invalidate_elasticsearch_indexes_cache
        project.invalidate_elasticsearch_indexes_cache!
      end

      if project.maintaining_elasticsearch? && project.maintaining_indexed_associations?
        # If the project is indexed, the project and all associated data are queued for indexing
        # to make sure the namespace_ancestry field gets updated in each document.
        # Delete the project record with old routing from the index
        ::Elastic::ProcessInitialBookkeepingService.track!(build_document_reference(project))
        ::Elastic::ProcessInitialBookkeepingService.backfill_projects!(project, skip_projects: true)

        delete_old_project(project, old_namespace_id)
      elsif should_invalidate_elasticsearch_indexes_cache && ::Gitlab::CurrentSettings.elasticsearch_indexing?
        # If the new namespace isn't indexed, the project should no longer exist in the index
        # and will be deleted asynchronously. If all projects are indexed, queue the project for indexing
        # to update the namespace field and remove the old document from the index.

        keep_project_in_index = ::Feature.enabled?(:search_index_all_projects, project.root_namespace)

        ::Elastic::ProcessInitialBookkeepingService.track!(build_document_reference(project)) if keep_project_in_index

        delete_old_project(project, old_namespace_id)
      end
    end

    private

    def should_invalidate_elasticsearch_indexes_cache?(old_namespace_id, new_namespace_id)
      # When a project is moved to a new namespace, invalidate the Elasticsearch cache if
      # Elasticsearch limit indexing is enabled and the indexing settings are different between the two namespaces.
      return false unless ::Gitlab::CurrentSettings.elasticsearch_limit_indexing?

      old_namespace = Namespace.find_by(id: old_namespace_id) # rubocop: disable CodeReuse/ActiveRecord
      new_namespace = Namespace.find_by(id: new_namespace_id) # rubocop: disable CodeReuse/ActiveRecord

      return ::Gitlab::CurrentSettings.elasticsearch_limit_indexing? unless old_namespace && new_namespace

      old_namespace.use_elasticsearch? != new_namespace.use_elasticsearch?
    end

    def build_document_reference(project)
      return project if project_routing_applied?

      Gitlab::Elastic::DocumentReference.new(Project, project.id, project.es_id, "n_#{project.root_ancestor.id}")
    end

    def delete_old_project(project, old_namespace_id)
      if project_routing_applied?
        ElasticDeleteProjectWorker.perform_async(project.id, project.es_id, namespace_routing_id: old_namespace_id)
      else
        ElasticDeleteProjectWorker.perform_async(project.id, project.es_id)
      end
    end

    def project_routing_applied?
      ::Elastic::DataMigrationService.migration_has_finished?(:reindex_projects_to_apply_routing)
    end
  end
end
