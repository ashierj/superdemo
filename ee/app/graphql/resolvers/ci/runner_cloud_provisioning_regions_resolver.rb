# frozen_string_literal: true

module Resolvers
  module Ci
    class RunnerCloudProvisioningRegionsResolver < Resolvers::Ci::RunnerCloudProvisioningBaseResolver
      type Types::Ci::RunnerCloudProvisioningRegionType.connection_type, null: true

      description 'Regions available for provisioning a runner.'

      max_page_size GoogleCloudPlatform::Compute::ListRegionsService::MAX_RESULTS_LIMIT
      default_page_size GoogleCloudPlatform::Compute::ListRegionsService::MAX_RESULTS_LIMIT

      def resolve(after: nil, first: nil)
        response = GoogleCloudPlatform::Compute::ListRegionsService
          .new(project: project, current_user: current_user, params: default_params(after, first))
          .execute

        externally_paginated_array(response, after)
      end
    end
  end
end
