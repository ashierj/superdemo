# frozen_string_literal: true

module EE
  module WorkItems
    module ParentLinks
      module DestroyService
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        private

        override :create_notes
        def create_notes
          return if params.fetch(:synced_work_item, false)

          super
        end

        override :permission_to_remove_relation?
        def permission_to_remove_relation?
          return true if params.fetch(:synced_work_item, false)

          super
        end
      end
    end
  end
end
