# frozen_string_literal: true

module CloudConnector
  class Access < ApplicationRecord
    self.table_name = 'cloud_connector_access'
    validates :data, json_schema: { filename: "cloud_connector_access" }
    validates :data, presence: true

    def self.service_start_date_for(service)
      last_record = last
      return unless last_record

      service_data = last_record.data["available_services"].find { |s| s["name"] == service }
      return unless service_data

      Time.zone.parse(service_data["serviceStartTime"])
    end
  end
end
