# frozen_string_literal: true

module Autocomplete
  class GroupSubgroupsFinder
    attr_reader :current_user, :params

    LIMIT = 50

    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params
    end

    def include_parent_descendants?
      Gitlab::Utils.to_boolean(params[:include_parent_descendants])
    end

    def group_id
      params[:group_id]
    end

    # rubocop: disable CodeReuse/Finder
    def execute
      group = ::Autocomplete::GroupFinder.new(current_user, nil, group_id: group_id).execute
      GroupsFinder.new(current_user, parent: group,
        include_parent_descendants: include_parent_descendants?).execute.limit(LIMIT)
    end
    # rubocop: enable CodeReuse/Finder
  end
end
