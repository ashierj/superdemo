# frozen_string_literal: true

module Resolvers
  module Ci
    class RunnerCloudProvisioningMachineTypesResolver < Resolvers::Ci::RunnerCloudProvisioningBaseResolver
      type Types::Ci::RunnerCloudProvisioningMachineTypeType.connection_type, null: true

      description 'Machine types available for provisioning a runner.'

      argument :zone, GraphQL::Types::String,
        required: true,
        description: 'Zone for which to retrieve machine types.'

      max_page_size GoogleCloudPlatform::Compute::ListMachineTypesService::MAX_RESULTS_LIMIT
      default_page_size GoogleCloudPlatform::Compute::ListMachineTypesService::MAX_RESULTS_LIMIT

      def resolve(zone:, after: nil, first: nil)
        response = GoogleCloudPlatform::Compute::ListMachineTypesService
          .new(project: project, current_user: current_user, zone: zone, params: default_params(after, first))
          .execute

        externally_paginated_array(response, after)
      end
    end
  end
end
