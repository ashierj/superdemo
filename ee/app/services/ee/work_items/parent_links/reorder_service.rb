# frozen_string_literal: true

module EE
  module WorkItems
    module ParentLinks
      module ReorderService
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        private

        override :can_admin_link?
        def can_admin_link?(work_item)
          return true if params.fetch(:synced_work_item, false)

          super
        end
      end
    end
  end
end
