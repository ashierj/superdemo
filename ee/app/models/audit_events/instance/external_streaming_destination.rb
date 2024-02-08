# frozen_string_literal: true

module AuditEvents
  module Instance
    class ExternalStreamingDestination < ApplicationRecord
      include Limitable
      include ExternallyStreamable

      self.limit_name = 'external_audit_event_destinations'
      self.limit_scope = Limitable::GLOBAL_SCOPE
      self.table_name = 'audit_events_instance_external_streaming_destinations'

      validates :name, uniqueness: true
    end
  end
end
