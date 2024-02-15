# frozen_string_literal: true

module Types
  module Ci
    # rubocop:disable Graphql/AuthorizeTypes -- This object is only available through one field, which is authorized. This type is mapped onto a simple hash, and therefore will not have a policy class for it.
    class RunnerCloudProvisioningZoneType < BaseObject
      graphql_name 'CiRunnerCloudProvisioningZone'
      description 'Zone used for runner cloud provisioning.'

      field :name, GraphQL::Types::String,
        null: true, description: 'Name of the zone.'

      field :description, GraphQL::Types::String,
        null: true, description: 'Description of the zone.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
