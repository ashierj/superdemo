# frozen_string_literal: true

module GoogleCloudPlatform
  module Compute
    class ListMachineTypesService < ::GoogleCloudPlatform::Compute::BaseService
      MISSING_ZONE_ERROR_RESPONSE = ServiceResponse.error(message: 'Zone value must be provided').freeze

      def initialize(project:, current_user:, zone:, params: {})
        super(project: project, current_user: current_user, params: params.merge(zone: zone))
      end

      private

      def zone
        params[:zone]
      end

      def call_client
        return MISSING_ZONE_ERROR_RESPONSE if zone.blank?

        machine_types = client.machine_types(
          zone: zone,
          filter: filter,
          max_results: max_results,
          page_token: page_token,
          order_by: order_by
        )

        ServiceResponse.success(payload: {
          items: machine_types.items.map { |t| { name: t.name, description: t.description, zone: t.zone } },
          next_page_token: machine_types.next_page_token
        })
      end
    end
  end
end
