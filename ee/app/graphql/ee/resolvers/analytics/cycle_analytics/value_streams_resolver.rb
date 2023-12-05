# frozen_string_literal: true

module EE
  module Resolvers
    module Analytics
      module CycleAnalytics
        module ValueStreamsResolver
          extend ::Gitlab::Utils::Override

          override :resolve
          def resolve
            unless ::Gitlab::Analytics::CycleAnalytics.licensed?(parent_namespace)
              return if object.is_a?(Group) # Group value streams only exists on EE

              return super
            end

            parent_namespace.value_streams.preload_associated_models.order_by_name_asc
          end

          private

          def parent_namespace
            object.try(:project_namespace) || object
          end
        end
      end
    end
  end
end
