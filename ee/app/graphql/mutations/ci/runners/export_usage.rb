# frozen_string_literal: true

module Mutations
  module Ci
    module Runners
      class ExportUsage < BaseMutation
        graphql_name 'RunnersExportUsage'

        argument :type, ::Types::Ci::RunnerTypeEnum,
          required: false,
          description: 'Scope of the runners to include in the report.'

        argument :max_project_count, ::GraphQL::Types::Int,
          required: false,
          description:
            "Maximum number of projects to return. All other runner usage will be attributed " \
            "to a '<Other projects>' entry. " \
            "Defaults to #{::Ci::Runners::GenerateUsageCsvService::DEFAULT_PROJECT_COUNT} projects."

        def ready?(**args)
          raise_resource_not_available_error! unless Ability.allowed?(current_user, :read_runner_usage)

          max_project_count = args.fetch(
            :max_project_count, ::Ci::Runners::GenerateUsageCsvService::DEFAULT_PROJECT_COUNT
          )

          unless max_project_count.between?(1, ::Ci::Runners::GenerateUsageCsvService::MAX_PROJECT_COUNT)
            raise Gitlab::Graphql::Errors::ArgumentError,
              "maxProjectCount must be between 1 and #{::Ci::Runners::GenerateUsageCsvService::MAX_PROJECT_COUNT}"
          end

          super
        end

        def resolve(type: nil, max_project_count: nil)
          ::Ci::Runners::ExportUsageCsvWorker.perform_async( # rubocop: disable CodeReuse/Worker -- this worker sends out emails
            current_user.id, { runner_type: ::Ci::Runner.runner_types[type], max_project_count: max_project_count }
          )

          {
            errors: []
          }
        end
      end
    end
  end
end
