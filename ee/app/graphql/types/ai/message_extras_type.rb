# frozen_string_literal: true

module Types
  module Ai
    # rubocop: disable Graphql/AuthorizeTypes
    class MessageExtrasType < Types::BaseObject
      graphql_name 'AiMessageExtras'
      description "Extra metadata for AI message."

      field :sources, [GraphQL::Types::JSON],
        null: true,
        description: "Sources used to form the message."

      field :has_feedback, GraphQL::Types::Boolean,
        null: true,
        description: "Whether the user has provided feedback for the mesage."
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
