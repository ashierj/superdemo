# frozen_string_literal: true

module Mutations
  module Ci
    module Runners
      class ExportUsage < BaseMutation
        graphql_name 'RunnersExportUsage'

        argument :type, ::Types::Ci::RunnerTypeEnum,
          required: false,
          description: 'Scope of the runners to include in the report.'

        def ready?(**args)
          raise_resource_not_available_error! unless Ability.allowed?(current_user, :read_runner_usage)

          super
        end

        def resolve(type: nil)
          type = ::Ci::Runner.runner_types[type]
          ::Ci::Runners::ExportUsageCsvWorker.perform_async(current_user.id, type) # rubocop: disable CodeReuse/Worker -- this worker sends out emails

          {
            errors: []
          }
        end
      end
    end
  end
end
