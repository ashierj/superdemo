# frozen_string_literal: true

module Resolvers
  module Ci
    class RunnerCloudProvisioningZonesResolver < Resolvers::Ci::RunnerCloudProvisioningBaseResolver
      type Types::Ci::RunnerCloudProvisioningZoneType.connection_type, null: true

      description 'Zones available for provisioning a runner.'

      argument :region, GraphQL::Types::String,
        required: false,
        description: 'Region for which to retrieve zones. Returns all zones if not specified.'

      max_page_size GoogleCloudPlatform::Compute::ListZonesService::MAX_RESULTS_LIMIT
      default_page_size GoogleCloudPlatform::Compute::ListZonesService::MAX_RESULTS_LIMIT

      def resolve(region: nil, after: nil, first: nil)
        params = default_params(after, first)
        params[:filter] = "name=#{region}-*" if region

        response = GoogleCloudPlatform::Compute::ListZonesService
          .new(project: project, current_user: current_user, params: params)
          .execute

        externally_paginated_array(response, after)
      end
    end
  end
end
