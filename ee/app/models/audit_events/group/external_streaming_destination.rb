# frozen_string_literal: true

module AuditEvents
  module Group
    class ExternalStreamingDestination < ApplicationRecord
      include Limitable
      include ExternallyStreamable

      self.limit_name = 'external_audit_event_destinations'
      self.limit_scope = :group
      self.table_name = 'audit_events_group_external_streaming_destinations'

      belongs_to :group, class_name: '::Group', inverse_of: :audit_events
      validate :top_level_group?
      validates :name, uniqueness: { scope: :group_id }

      def top_level_group?
        errors.add(:group, 'must not be a subgroup. Use a top-level group.') if group.subgroup?
      end
    end
  end
end
