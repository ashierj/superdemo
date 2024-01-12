# frozen_string_literal: true

module Mutations
  module Ai
    module Agents
      class Base < BaseMutation
        authorize :write_ai_agents

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: "Project to which the agent belongs."

        field :agent,
          Types::Ai::Agents::AgentType,
          null: true,
          description: 'Agent after mutation.'
      end
    end
  end
end
