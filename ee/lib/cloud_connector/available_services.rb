# frozen_string_literal: true

module CloudConnector
  class AvailableServices
    include Singleton

    CLOUD_CONNECTOR_SERVICES_KEY = 'cloud-connector:services'

    class << self
      def find_by_name(name)
        instance.available_services[name]
      end
    end

    def available_services
      Rails.cache.fetch(CLOUD_CONNECTOR_SERVICES_KEY) do
        service_descriptors = access_record_data&.[]('available_services') || []
        service_descriptors.map { |access_data| build_available_service_data(access_data) }.index_by(&:name)
      end
    end

    private

    def access_record_data
      ::CloudConnector::Access.last&.data
    end

    def parse_time(time)
      Time.zone.parse(time).utc if time
    end

    def build_available_service_data(access_data)
      ::CloudConnector::AvailableServiceData.new(
        access_data['name'].to_sym,
        parse_time(access_data["serviceStartTime"]),
        access_data["bundledWith"].to_a
      )
    end
  end
end
