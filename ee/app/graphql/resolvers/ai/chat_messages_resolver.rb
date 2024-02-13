# frozen_string_literal: true

module Resolvers
  module Ai
    class ChatMessagesResolver < BaseResolver
      type Types::Ai::MessageType, null: false

      argument :request_ids, [GraphQL::Types::ID],
        required: false,
        description: 'Array of request IDs to fetch.'

      argument :roles, [Types::Ai::MessageRoleEnum],
        required: false,
        description: 'Array of roles to fetch.'

      argument :agent_version_id,
        ::Types::GlobalIDType[::Ai::AgentVersion],
        required: false,
        description: "Global ID of the agent to answer the chat."

      def resolve(**args)
        return [] unless current_user

        agent_version_id = args[:agent_version_id]&.model_id

        ::Gitlab::Llm::ChatStorage.new(current_user, agent_version_id).messages_by(args).map(&:to_h)
      end
    end
  end
end
