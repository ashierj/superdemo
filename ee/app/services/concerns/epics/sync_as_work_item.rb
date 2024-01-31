# frozen_string_literal: true

module Epics
  module SyncAsWorkItem
    ALLOWED_PARAMS = %i[
      title description confidential author created_at updated_at updated_by_id
      last_edited_by_id last_edited_at closed_by_id closed_at state_id external_key
    ].freeze

    def create_work_item_for(epic)
      create_params = params.to_h.with_indifferent_access.slice(*ALLOWED_PARAMS)
      work_item_params = {
        work_item_type: WorkItems::Type.default_by_type(:epic),
        iid: epic.iid,
        created_at: epic.created_at,
        extra_params: { synced_work_item: true }
      }

      work_item_params[:title_html] = epic.title_html if params[:title].present?
      work_item_params[:description_html] = epic.description_html if params[:description].present?

      ::WorkItems::CreateService.new(
        container: epic.group,
        current_user: current_user,
        params: create_params.merge(work_item_params)
      ).execute_without_rate_limiting
    end

    def update_work_item_for!(epic)
      return unless work_item_sync_enabled?
      return unless epic.work_item

      service_response = ::WorkItems::UpdateService.new(
        container: epic.group,
        current_user: current_user,
        params: update_params(epic)
      ).execute(epic.work_item)

      return true if service_response[:status] == :success

      error_message = service_response.payload[:errors]&.full_messages&.join(', ')
      log_error("Unable to sync work item: #{error_message}. Group ID: #{group.id}")
      raise StandardError, error_message
    end

    private

    def update_params(epic)
      work_item_params = params.to_h.with_indifferent_access.slice(*ALLOWED_PARAMS)
      work_item_params = work_item_params.merge({
        updated_by: epic.updated_by,
        updated_at: epic.updated_at,
        last_edited_at: epic.last_edited_at,
        last_edited_by: epic.last_edited_by,
        extra_params: { synced_work_item: true }
      })

      work_item_params[:title_html] = epic.title_html if params[:title].present?
      work_item_params[:description_html] = epic.description_html if params[:description].present?

      work_item_params
    end

    def work_item_sync_enabled?
      ::Feature.enabled?(:epic_creation_with_synced_work_item, group, type: :wip)
    end
  end
end
