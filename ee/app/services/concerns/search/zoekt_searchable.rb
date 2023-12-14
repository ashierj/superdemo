# frozen_string_literal: true

module Search
  module ZoektSearchable
    def use_zoekt?
      # TODO: rename to search_code_with_zoekt?
      # https://gitlab.com/gitlab-org/gitlab/-/issues/421619
      return false if params[:basic_search]
      return false unless ::Feature.enabled?(:search_code_with_zoekt, current_user)
      return false unless ::License.feature_available?(:zoekt_code_search)
      return false if current_user && !current_user.enabled_zoekt?
      return false unless zoekt_searchable_scope?

      zoekt_node_available_for_search?
    end

    def zoekt_searchable_scope
      raise NotImplementedError
    end

    def zoekt_searchable_scope?
      scope == 'blobs' && zoekt_searchable_scope.try(:search_code_with_zoekt?)
    end

    def zoekt_projects
      raise NotImplementedError
    end

    def zoekt_node_id
      @zoekt_node_id ||= zoekt_nodes.first.id
    end

    def zoekt_nodes
      # Note: there will be more zoekt nodes whenever replicas are introduced.
      @zoekt_nodes ||= ::Search::Zoekt::Node.for_namespace(zoekt_searchable_scope.root_ancestor.id)
    end

    def zoekt_node_available_for_search?
      ::Search::Zoekt::CircuitBreaker.new(*zoekt_nodes).operational?
    end

    def zoekt_search_results
      ::Gitlab::Zoekt::SearchResults.new(
        current_user,
        params[:search],
        zoekt_projects,
        node_id: zoekt_node_id,
        order_by: params[:order_by],
        sort: params[:sort],
        filters: { language: params[:language] }
      )
    end
  end
end
