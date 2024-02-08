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
          return if child.synced_epic.present?

          super
        end
      end
    end
  end
end
