# frozen_string_literal: true

module Epics
  module SyncAsWorkItem
    ALLOWED_PARAMS = %i[
      title description confidential author created_at updated_at updated_by_id last_edited_by_id
      last_edited_at closed_by_id closed_at state_id
    ].freeze

    def create_work_item_for(epic)
      create_params = params.to_h.with_indifferent_access.slice(*ALLOWED_PARAMS)
      work_item_params = {
        work_item_type: WorkItems::Type.default_by_type(:epic),
        iid: epic.iid,
        created_at: epic.created_at,
        extra_params: { synced_work_item: true }
      }

      ::WorkItems::CreateService.new(
        container: epic.group,
        current_user: current_user,
        params: create_params.merge(work_item_params),
        widget_params: widget_params
      ).execute_without_rate_limiting
    end

    private

    def widget_params
      work_item_type = WorkItems::Type.default_by_type(:epic)

      work_item_type.widgets.each_with_object({}) do |widget, widget_params|
        attributes = params.slice(*widget.sync_params)
        next unless attributes.present?

        widget_params[widget.api_symbol] = widget.process_sync_params(attributes)
      end
    end
  end
end
