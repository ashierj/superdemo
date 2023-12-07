# frozen_string_literal: true

module EE
  module Resolvers
    module Analytics
      module CycleAnalytics
        module StagesResolver
          extend ::Gitlab::Utils::Override

          override :resolve
          def resolve
            return super unless ::Gitlab::Analytics::CycleAnalytics.licensed?(namespace)

            BatchLoader::GraphQL.for(object.id).batch(key: object.class.name, cache: false) do |ids, loader, _|
              stages = list_stages({ value_streams_ids: ids })

              grouped_stages = stages.present? ? stages.group_by(&:value_stream_id) : {}

              ids.each do |id|
                loader.call(id, grouped_stages[id] || [])
              end
            end
          end

          private

          override :namespace
          def namespace
            return super unless object.at_group_level?

            object.namespace
          end
        end
      end
    end
  end
end
