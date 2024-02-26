# frozen_string_literal: true

module EE
  module WorkItems
    module ParentLinks
      module CreateService
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        private

        override :create_notes_and_resource_event
        def create_notes_and_resource_event(work_item, _link)
          return if params.fetch(:synced_work_item, false)

          super
        end

        override :can_admin_link?
        def can_admin_link?(work_item)
          return true if params.fetch(:synced_work_item, false)

          super
        end
      end
    end
  end
end
