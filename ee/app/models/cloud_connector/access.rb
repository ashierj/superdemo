# frozen_string_literal: true

module CloudConnector
  class Access < ApplicationRecord
    self.table_name = 'cloud_connector_access'
    validates :data, json_schema: { filename: "cloud_connector_access" }
    validates :data, presence: true
  end
end
