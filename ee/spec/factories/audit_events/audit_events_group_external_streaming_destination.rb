# frozen_string_literal: true

FactoryBot.define do
  factory :audit_events_group_external_streaming_destination,
    class: 'AuditEvents::Group::ExternalStreamingDestination' do
    group
    type { 'http' }
    config { { url: 'https://www.example.com' } }
    secret_token { 'hello' }
  end
end
