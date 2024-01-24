# frozen_string_literal: true

module Types
  module Ci
    class RunnerUsageByProjectType < BaseObject
      graphql_name 'RunnerUsageByProject'
      description 'Runner usage in minutes by project.'

      authorize :read_jobs_statistics

      field :project, ::Types::ProjectType,
        null: true, description: 'Project that the usage refers to. Null means "Other projects".'

      field :ci_minutes_used, GraphQL::Types::Int,
        null: false, description: 'Amount of minutes used during the selected period.'

      field :ci_build_count, GraphQL::Types::Int,
        null: false, description: 'Amount of builds executed during the selected period.'

      def project
        return unless object[:project_id]

        BatchLoader::GraphQL.for(object[:project_id]).batch do |project_ids, loader|
          Project.id_in(project_ids).each do |project|
            loader.call(project.id, project)
          end
        end
      end
    end
  end
end
