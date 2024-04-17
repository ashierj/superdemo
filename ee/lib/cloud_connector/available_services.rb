# frozen_string_literal: true

module CloudConnector
  class AvailableServices
    include Singleton
    include SelfManaged::AccessDataReader

    CLOUD_CONNECTOR_SERVICES_KEY = 'cloud-connector:services'

    class << self
      def find_by_name(name)
        service_data_map = instance.available_services

        return CloudConnector::MissingServiceData.new if service_data_map.empty?

        service_data_map[name]
      end
    end

    def available_services
      Rails.cache.fetch(CLOUD_CONNECTOR_SERVICES_KEY) do
        read_available_services
      end
    end
  end
end
