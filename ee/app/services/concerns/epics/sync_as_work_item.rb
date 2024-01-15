# frozen_string_literal: true

module Epics
  module SyncAsWorkItem
    ALLOWED_PARAMS = %i[title description confidential].freeze

    def create_work_item_for(epic)
      create_params = params.to_h.with_indifferent_access.slice(*ALLOWED_PARAMS)
      create_params[:work_item_type] = WorkItems::Type.default_by_type(:epic)
      create_params[:iid] = epic.iid
      create_params[:extra_params] = { synced_work_item: true }

      ::WorkItems::CreateService.new(
        container: epic.group,
        current_user: current_user,
        params: create_params
      ).execute_without_rate_limiting
    end
  end
end
