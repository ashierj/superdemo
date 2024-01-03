# frozen_string_literal: true

FactoryBot.define do
  factory :cloud_connector_access, class: 'CloudConnector::Access' do
    data { { available_services: [{ name: "code_suggestions", service_start_time: "2024-02-15T00:00:00Z" }] } }
  end
end
