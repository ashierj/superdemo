# frozen_string_literal: true

module Types
  module Ci
    class RunnerCloudProvisioningOptionsType < BaseObject
      graphql_name 'CiRunnerCloudProvisioningOptions'
      description 'Options for runner cloud provisioning.'

      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorize :read_runner_cloud_provisioning_options

      field :regions, Types::Ci::RunnerCloudProvisioningRegionType.connection_type,
        null: true,
        resolver: ::Resolvers::Ci::RunnerCloudProvisioningRegionsResolver,
        connection_extension: Gitlab::Graphql::Extensions::ForwardOnlyExternallyPaginatedArrayExtension

      field :zones, Types::Ci::RunnerCloudProvisioningZoneType.connection_type,
        null: true,
        resolver: ::Resolvers::Ci::RunnerCloudProvisioningZonesResolver,
        connection_extension: Gitlab::Graphql::Extensions::ForwardOnlyExternallyPaginatedArrayExtension

      field :machine_types,
        Types::Ci::RunnerCloudProvisioningMachineTypeType.connection_type,
        null: true,
        resolver: ::Resolvers::Ci::RunnerCloudProvisioningMachineTypesResolver,
        connection_extension: Gitlab::Graphql::Extensions::ForwardOnlyExternallyPaginatedArrayExtension
    end
  end
end
