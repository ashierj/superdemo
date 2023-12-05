# frozen_string_literal: true

module EE
  module Resolvers
    module Analytics
      module CycleAnalytics
        module StagesResolver
          extend ::Gitlab::Utils::Override

          private

          def namespace
            return super unless object.at_group_level?

            object.namespace
          end
        end
      end
    end
  end
end
