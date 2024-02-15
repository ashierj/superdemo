# frozen_string_literal: true

module Types
  module Ci
    class RunnerGoogleCloudProvisioningOptionsType < BaseObject
      graphql_name 'CiRunnerGoogleCloudProvisioningOptions'
      description 'Options for runner Google Cloud provisioning.'

      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorize :read_runner_cloud_provisioning_options

      field :regions, Types::Ci::RunnerCloudProvisioningRegionType.connection_type,
        description: 'Regions available for provisioning a runner.',
        null: true,
        connection_extension: Gitlab::Graphql::Extensions::ForwardOnlyExternallyPaginatedArrayExtension,
        max_page_size: GoogleCloudPlatform::Compute::ListRegionsService::MAX_RESULTS_LIMIT,
        default_page_size: GoogleCloudPlatform::Compute::ListRegionsService::MAX_RESULTS_LIMIT

      field :zones, Types::Ci::RunnerCloudProvisioningZoneType.connection_type,
        description: 'Zones available for provisioning a runner.',
        null: true,
        connection_extension: Gitlab::Graphql::Extensions::ForwardOnlyExternallyPaginatedArrayExtension,
        max_page_size: GoogleCloudPlatform::Compute::ListZonesService::MAX_RESULTS_LIMIT,
        default_page_size: GoogleCloudPlatform::Compute::ListZonesService::MAX_RESULTS_LIMIT do
          argument :region, GraphQL::Types::String, required: false,
            description: 'Region to retrieve zones for. Returns all zones if not specified.'
        end

      field :machine_types,
        Types::Ci::RunnerCloudProvisioningMachineTypeType.connection_type,
        description: 'Machine types available for provisioning a runner.',
        null: true,
        connection_extension: Gitlab::Graphql::Extensions::ForwardOnlyExternallyPaginatedArrayExtension,
        max_page_size: GoogleCloudPlatform::Compute::ListMachineTypesService::MAX_RESULTS_LIMIT,
        default_page_size: GoogleCloudPlatform::Compute::ListMachineTypesService::MAX_RESULTS_LIMIT do
          argument :zone, GraphQL::Types::String, required: true, description: 'Zone to retrieve machine types for.'
        end

      def self.authorized?(object, context)
        super(object[:project], context)
      end

      def regions(after: nil, first: nil)
        response = GoogleCloudPlatform::Compute::ListRegionsService
          .new(project: project, current_user: current_user,
            params: default_params(after, first).merge(google_cloud_project_id: google_cloud_project_id))
          .execute

        externally_paginated_array(response, after)
      end

      def zones(region: nil, after: nil, first: nil)
        params = default_params(after, first)
        params[:filter] = "name=#{region}-*" if region
        params[:google_cloud_project_id] = google_cloud_project_id if google_cloud_project_id

        response = GoogleCloudPlatform::Compute::ListZonesService
          .new(project: project, current_user: current_user, params: params)
          .execute

        externally_paginated_array(response, after)
      end

      def machine_types(zone:, after: nil, first: nil)
        response = GoogleCloudPlatform::Compute::ListMachineTypesService
          .new(
            project: project, current_user: current_user, zone: zone,
            params: default_params(after, first).merge(google_cloud_project_id: google_cloud_project_id)
          )
          .execute

        externally_paginated_array(response, after)
      end

      private

      def project
        object[:project]
      end

      def google_cloud_project_id
        object[:cloud_project_id]
      end

      def default_params(after, first)
        { max_results: first, page_token: after }.compact
      end

      def externally_paginated_array(response, after)
        raise_resource_not_available_error!(response.message) if response.error?

        Gitlab::Graphql::ExternallyPaginatedArray.new(
          after,
          response.payload[:next_page_token],
          *response.payload[:items]
        )
      end
    end
  end
end
