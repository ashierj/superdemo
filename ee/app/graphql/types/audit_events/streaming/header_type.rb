# frozen_string_literal: true

# Headers are only available through destinations
# which are already authorized.
#
# rubocop:disable Graphql/AuthorizeTypes
module Types
  module AuditEvents
    module Streaming
      class HeaderType < ::Types::BaseObject
        graphql_name 'AuditEventStreamingHeader'
        description 'Represents a HTTP header key/value that belongs to an audit streaming destination.'

        field :id, GraphQL::Types::ID,
              null: false,
              description: 'ID of the header.'

        field :key, GraphQL::Types::String,
              null: false,
              description: 'Key of the header.'

        field :value, GraphQL::Types::String,
              null: false,
              description: 'Value of the header.'
      end
    end
  end
end
# rubocop:enable Graphql/AuthorizeTypes
