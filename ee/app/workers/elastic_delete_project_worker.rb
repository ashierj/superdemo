# frozen_string_literal: true

class ElasticDeleteProjectWorker
  include ApplicationWorker

  data_consistency :always
  prepend Elastic::IndexingControl

  sidekiq_options retry: 2
  feature_category :global_search
  urgency :throttled
  idempotent!

  def perform(project_id, es_id, options = {})
    options = options.with_indifferent_access
    remove_project_document(es_id) if options.fetch(:delete_project, true)
    remove_children_documents(project_id, es_id)
    helper.remove_wikis_from_the_standalone_index(project_id, 'Project', options[:namespace_routing_id]) # Wikis have different routing that's why one more query is needed.
    IndexStatus.for_project(project_id).delete_all
  end

  private

  def indices
    # Some standalone indices may not be created yet if pending advanced search migrations exist
    # Exclude Epic as projects can not have epics
    # Exclude Wiki as wikis have a different routing structure
    # Project will be removed independently
    excluded_classes = [Epic, Wiki, Project]

    standalone_indices = helper.standalone_indices_proxies(exclude_classes: excluded_classes).select do |klass|
      alias_name = helper.klass_to_alias_name(klass: klass)
      helper.index_exists?(index_name: alias_name)
    end

    [helper.target_name] + standalone_indices.map(&:index_name)
  end

  def remove_project_document(es_id)
    helper.client.delete(index: Project.index_name, id: es_id)
  rescue Elasticsearch::Transport::Transport::Errors::NotFound
    # no-op
  end

  def remove_children_documents(project_id, es_id)
    helper.client.delete_by_query({
      index: indices,
      routing: es_id,
      body: {
        query: {
          bool: {
            should: [
              {
                term: {
                  _id: es_id
                }
              },
              {
                term: {
                  project_id: project_id
                }
              },
              {
                term: {
                  # We never set `project_id` for commits instead they have a nested rid which is the project_id
                  "commit.rid" => project_id
                }
              },
              {
                term: {
                  "rid" => project_id
                }
              },
              {
                term: {
                  target_project_id: project_id # handle merge_request which previously did not store project_id and only stored target_project_id
                }
              }
            ]
          }
        }
      }
    })
  end

  def helper
    @helper ||= Gitlab::Elastic::Helper.default
  end
end
