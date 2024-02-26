# frozen_string_literal: true

module EE
  module WorkItemPolicy
    extend ActiveSupport::Concern

    prepended do
      condition(:has_synced_epic, scope: :subject) do
        @subject.work_item_type&.epic? && @subject.synced_epic.present?
      end

      rule { has_synced_epic }.policy do
        prevent :admin_work_item_link
        prevent :admin_work_item
        prevent :update_work_item
        prevent :set_work_item_metadata
        prevent :create_note
        prevent :award_emoji
        prevent :create_todo
        prevent :update_subscription
        prevent :create_requirement_test_report
        prevent :admin_parent_link
      end
    end
  end
end
