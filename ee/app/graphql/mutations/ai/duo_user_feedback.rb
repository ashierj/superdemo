# frozen_string_literal: true

module Mutations
  module Ai
    class DuoUserFeedback < BaseMutation
      graphql_name 'DuoUserFeedback'

      argument :agent_version_id, ::Types::GlobalIDType[::Ai::AgentVersion], required: false,
        description: "Global ID of the agent to answer the chat."
      argument :ai_message_id, GraphQL::Types::String, required: true, description: 'ID of the AI Message.'
      argument :extended_feedback, GraphQL::Types::String, required: false, description: 'Freeform user feedback.'
      argument :selected_feedback_options, [GraphQL::Types::String], required: false,
        description: 'User selected feedback options.'

      def resolve(**args)
        raise_resource_not_available_error! unless current_user

        chat_storage = ::Gitlab::Llm::ChatStorage.new(current_user, args[:agent_version_id]&.model_id)
        message = chat_storage.messages.find { |m| m.id == args[:ai_message_id] }

        raise_resource_not_available_error! unless message

        chat_storage.set_has_feedback(message)

        { errors: [] }
      end
    end
  end
end
