# frozen_string_literal: true

module Mutations
  module AuditEvents
    module Instance
      module AuditEventStreamingDestinations
        class Create < Base
          graphql_name 'InstanceAuditEventStreamingDestinationsCreate'

          argument :config, GraphQL::Types::JSON, # rubocop:disable Graphql/JSONType -- Different type of destinations will have different configs
            required: true,
            description: 'Destination config.'

          argument :name, GraphQL::Types::String,
            required: false,
            description: 'Destination name.'

          argument :category, GraphQL::Types::String,
            required: true,
            description: 'Destination category.'

          argument :secret_token, GraphQL::Types::String,
            required: true,
            description: 'Secret token.'

          field :external_audit_event_destination, ::Types::AuditEvents::Instance::StreamingDestinationType,
            null: true,
            description: 'Destination created.'

          def resolve(secret_token: nil, name: nil, category: nil, config: nil)
            destination = ::AuditEvents::Instance::ExternalStreamingDestination.new(secret_token: secret_token,
              name: name,
              config: config,
              category: category
            )

            audit(destination, action: :created) if destination.save

            {
              external_audit_event_destination: (destination if destination.persisted?),
              errors: Array(destination.errors)
            }
          end
        end
      end
    end
  end
end
