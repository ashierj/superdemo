# frozen_string_literal: true

module Search
  class ElasticGroupAssociationDeletionWorker
    include ApplicationWorker
    prepend ::Elastic::IndexingControl

    MAX_JOBS_PER_HOUR = 3600

    sidekiq_options retry: 3
    data_consistency :delayed
    feature_category :global_search
    urgency :throttled
    idempotent!

    def perform(group_id, ancestor_id, options = {})
      return unless ::Epic.elasticsearch_available?

      return remove_epics(group_id, ancestor_id) unless options[:include_descendants]

      # We have the return condition here because we still want to remove the deleted group epics in the above call
      group = Group.find_by_id(group_id)
      return if group.nil?

      # rubocop: disable CodeReuse/ActiveRecord -- We need only the ids of self_and_descendants groups
      group.self_and_descendants.each_batch { |groups| remove_epics(groups.pluck(:id), ancestor_id) }
      # rubocop: enable CodeReuse/ActiveRecord
    end

    private

    def client
      @client ||= ::Gitlab::Search::Client.new
    end

    def remove_epics(group_ids, ancestor_id)
      client.delete_by_query(
        {
          index: ::Elastic::Latest::EpicConfig.index_name,
          routing: "group_#{ancestor_id}",
          conflicts: 'proceed',
          timeout: "10m",
          body: {
            query: {
              bool: {
                filter: { terms: { group_id: Array.wrap(group_ids) } }
              }
            }
          }
        }
      )
    end
  end
end
