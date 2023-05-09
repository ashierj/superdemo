# frozen_string_literal: true

module Mutations
  module Ci
    module Ai
      class GenerateConfig < BaseMutation
        graphql_name 'CiAiGenerateConfig'

        authorize :read_project

        include FindsProject

        argument :project_path,
          GraphQL::Types::ID,
          required: true,
          description: 'Project path for the project related to the open config editor.'

        argument :user_content,
          GraphQL::Types::String,
          required: true,
          description: 'Content of the user message to be sent to the language model.'

        def resolve(project_path:, user_content:) # rubocop:disable Lint/UnusedMethodArgument
          authorized_find!(project_path)

          return { errors: ['Feature not available'] } unless Feature.enabled?(:ai_ci_config_generator, current_user)

          { errors: [] }
        end
      end
    end
  end
end
