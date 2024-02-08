# frozen_string_literal: true

FactoryBot.define do
  factory :audit_events_instance_external_streaming_destination,
    class: 'AuditEvents::Instance::ExternalStreamingDestination' do
    type { 'http' }
    config { { url: 'https://www.example.com' } }
    secret_token { 'hello' }
  end
end
