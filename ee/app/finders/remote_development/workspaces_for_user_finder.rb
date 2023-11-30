# frozen_string_literal: true

module RemoteDevelopment
  class WorkspacesForUserFinder
    attr_reader :user, :params

    def initialize(user:, params: {})
      @user = user
      @params = params
    end

    def execute
      # NOTE: This check is included in the :read_workspace ability, but we do it here to short
      #       circuit for performance if the user can't access the feature, because otherwise
      #       there is an N+1 call for each workspace via `authorize :read_workspace` in
      #       the graphql resolver.
      return Workspace.none unless user.can?(:access_workspaces_feature)

      items = user.workspaces
      items = by_ids(items)
      items = by_project_ids(items)
      items = include_actual_states(items)

      items.order_by('id_desc')
    end

    private

    def by_ids(items)
      return items unless params[:ids].present?

      items.id_in(params[:ids])
    end

    def by_project_ids(items)
      return items unless params[:project_ids].present?

      items.by_project_ids(params[:project_ids])
    end

    def include_actual_states(items)
      return items unless params[:include_actual_states].present?

      items.with_actual_states(params[:include_actual_states])
    end
  end
end
