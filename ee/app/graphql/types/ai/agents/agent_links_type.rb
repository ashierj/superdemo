# frozen_string_literal: true

module Types
  module Ai
    module Agents
      # rubocop: disable Graphql/AuthorizeTypes -- authorization in resolver/mutation
      class AgentLinksType < Types::BaseObject
        graphql_name 'AiAgentLinks'
        description 'Represents links to perform actions on the agent'

        present_using ::Ai::AgentPresenter

        field :show_path, GraphQL::Types::String,
          null: true,
          description: 'Path to the details page of the agent.',
          method: :path
      end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end
