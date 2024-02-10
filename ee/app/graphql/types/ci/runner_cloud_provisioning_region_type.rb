# frozen_string_literal: true

module Types
  module Ci
    # rubocop:disable Graphql/AuthorizeTypes -- This object is only available through one field, which is authorized. This type is mapped onto a simple hash, and therefore will not have a policy class for it.
    class RunnerCloudProvisioningRegionType < BaseObject
      graphql_name 'CiRunnerCloudProvisioningRegion'
      description 'Region used for runner cloud provisioning.'

      field :name, GraphQL::Types::String,
        null: true, description: 'Name of the region.'

      field :description, GraphQL::Types::String,
        null: true, description: 'Description of the region.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
