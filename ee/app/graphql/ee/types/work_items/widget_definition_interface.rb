# frozen_string_literal: true

module EE
  module Types
    module WorkItems
      module WidgetDefinitionInterface
        extend ActiveSupport::Concern

        EE_ORPHAN_TYPES = [
          ::Types::WorkItems::WidgetDefinitions::LabelsType
        ].freeze

        class_methods do
          extend ::Gitlab::Utils::Override

          override :resolve_type
          def resolve_type(object, context)
            if object == ::WorkItems::Widgets::Labels
              ::Types::WorkItems::WidgetDefinitions::LabelsType
            else
              super
            end
          end
        end

        prepended do
          orphan_types(*ce_orphan_types, *EE_ORPHAN_TYPES)
        end
      end
    end
  end
end
