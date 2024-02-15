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
          return if work_item.synced_epic.present?

          super
        end
      end
    end
  end
end
