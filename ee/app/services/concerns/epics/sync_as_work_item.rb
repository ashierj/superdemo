# frozen_string_literal: true

module Epics
  module SyncAsWorkItem
    SyncAsWorkItemError = Class.new(StandardError)

    ALLOWED_PARAMS = %i[
      title description confidential author created_at updated_at updated_by_id
      last_edited_by_id last_edited_at closed_by_id closed_at state_id external_key
    ].freeze

    def create_work_item_for!(epic)
      return unless work_item_sync_enabled?

      service_response = ::WorkItems::CreateService.new(
        container: epic.group,
        current_user: current_user,
        params: create_params(epic)
      ).execute_without_rate_limiting

      handle_response!(:create, service_response, epic)

      epic.issue_id = service_response.payload[:work_item].id
      epic.save!
    end

    def update_work_item_for!(epic)
      return unless work_item_sync_enabled?
      return unless epic.work_item

      service_response = ::WorkItems::UpdateService.new(
        container: epic.group,
        current_user: current_user,
        params: update_params(epic)
      ).execute(epic.work_item)

      handle_response!(:update, service_response, epic)
    end

    private

    def filtered_params
      params.to_h.with_indifferent_access.slice(*ALLOWED_PARAMS)
    end

    def create_params(epic)
      create_params = filtered_params.merge(
        work_item_type: WorkItems::Type.default_by_type(:epic),
        iid: epic.iid,
        created_at: epic.created_at,
        extra_params: { synced_work_item: true }
      )

      create_params[:title_html] = epic.title_html if params[:title].present?
      create_params[:description_html] = epic.description_html if params[:description].present?

      create_params
    end

    def update_params(epic)
      update_params = filtered_params.merge({
        updated_by: epic.updated_by,
        updated_at: epic.updated_at,
        last_edited_at: epic.last_edited_at,
        last_edited_by: epic.last_edited_by,
        extra_params: { synced_work_item: true }
      })

      update_params[:title_html] = epic.title_html if params[:title].present?
      update_params[:description_html] = epic.description_html if params[:description].present?

      update_params
    end

    def handle_response!(action, service_response, epic)
      return true if service_response[:status] == :success

      error_message = Array.wrap(service_response[:message])
      Gitlab::EpicWorkItemSync::Logger.error(
        message: "Not able to #{action} epic work item", error_message: error_message, group_id: group.id,
        epic_id: epic.id
      )

      raise SyncAsWorkItemError, error_message.join(", ")
    end

    def work_item_sync_enabled?
      ::Feature.enabled?(:epic_creation_with_synced_work_item, group, type: :wip)
    end
  end
end
