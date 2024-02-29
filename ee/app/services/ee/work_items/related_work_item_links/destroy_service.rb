# frozen_string_literal: true

module EE
  module WorkItems
    module RelatedWorkItemLinks
      module DestroyService
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        def initialize(issuable, user, params)
          @extra_params = params.delete(:extra_params)

          super
        end

        private

        override :create_notes
        def create_notes(link)
          super unless sync_work_item?
        end

        override :can_admin_work_item_link?
        def can_admin_work_item_link?(_resource)
          return true if sync_work_item?

          super
        end

        def sync_work_item?
          extra_params&.fetch(:synced_work_item, false)
        end

        attr_reader :extra_params
      end
    end
  end
end
