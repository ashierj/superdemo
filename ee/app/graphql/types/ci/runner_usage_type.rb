# frozen_string_literal: true

module Types
  module Ci
    class RunnerUsageType < BaseObject
      graphql_name 'CiRunnerUsage'
      description 'Runner usage.'

      authorize :read_runner_usage

      field :runner, ::Types::Ci::RunnerType,
        null: true, description: 'Runner that the usage refers to. Null means "Other runners".'

      field :ci_minutes_used, GraphQL::Types::Int,
        null: false, description: 'Amount of minutes used during the selected period.'

      field :ci_build_count, GraphQL::Types::Int,
        null: false, description: 'Amount of builds executed during the selected period.'

      def runner
        return unless object[:runner_id]

        ::Gitlab::Graphql::Loaders::BatchModelLoader.new(::Ci::Runner, object[:runner_id]).find
      end
    end
  end
end
