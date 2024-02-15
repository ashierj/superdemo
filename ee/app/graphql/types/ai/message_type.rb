# frozen_string_literal: true

module Types
  module Ai
    # rubocop: disable Graphql/AuthorizeTypes
    class MessageType < Types::BaseObject
      graphql_name 'AiMessage'
      description "AI features communication message"

      # rubocop:disable GraphQL/FieldHashKey
      field :id,
        GraphQL::Types::ID,
        description: 'UUID of the message.'
      # rubocop:enable GraphQL/FieldHashKey

      field :request_id, GraphQL::Types::String,
        null: true,
        description: 'UUID of the original request. Shared between chat prompt and response.'

      field :content, GraphQL::Types::String,
        null: true,
        description: 'Raw response content.'

      field :content_html, GraphQL::Types::String,
        null: true,
        description: 'Response content as HTML.'

      field :role,
        Types::Ai::MessageRoleEnum,
        null: false,
        description: 'Message owner role.'

      field :timestamp,
        Types::TimeType,
        null: false,
        description: 'Message creation timestamp.'

      field :chunk_id,
        GraphQL::Types::Int,
        null: true,
        description: 'Incremental ID for a chunk from a streamed message. Null when it is not a streamed message.'

      field :errors, [GraphQL::Types::String],
        null: true,
        description: 'Message errors.'

      field :type, Types::Ai::MessageTypeEnum,
        null: true,
        description: 'Message type.'

      field :extras,
        Types::Ai::MessageExtrasType,
        null: true,
        description: 'Extra message metadata.'

      field :agent_version_id,
        ::Types::GlobalIDType[::Ai::AgentVersion],
        null: true,
        description: 'Global ID of the agent version to answer the message.'

      def id
        object[:id]
      end

      def content_html
        return if object['chunk_id']

        banzai_options = {
          current_user: current_user,
          only_path: false,
          pipeline: :full,
          allow_comments: false,
          skip_project_check: true
        }

        Banzai.render_and_post_process(object['content'], banzai_options)
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
