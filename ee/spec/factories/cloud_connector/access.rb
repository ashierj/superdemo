# frozen_string_literal: true

FactoryBot.define do
  factory :cloud_connector_access, class: 'CloudConnector::Access' do
    data do
      {
        available_services: [
          {
            name: "code_suggestions",
            service_start_time: "2024-02-15T00:00:00Z",
            bundled_with: %w[duo_pro]
          },
          {
            name: "duo_chat",
            service_start_time: nil,
            bundled_with: %w[duo_pro duo_extra]
          }
        ]
      }
    end
  end
end
