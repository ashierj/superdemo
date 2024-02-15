# frozen_string_literal: true

module Types
  module Ci
    # rubocop:disable Graphql/AuthorizeTypes -- This object is only available through one field, which is authorized. This type is mapped onto a simple hash, and therefore will not have a policy class for it.
    class RunnerCloudProvisioningMachineTypeType < BaseObject
      graphql_name 'CiRunnerCloudProvisioningMachineType'
      description 'Machine type used for runner cloud provisioning.'

      field :zone, GraphQL::Types::String,
        null: true, description: 'Zone of the machine type.'

      field :name, GraphQL::Types::String,
        null: true, description: 'Name of the machine type.'

      field :description, GraphQL::Types::String,
        null: true, description: 'Description of the machine type.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
