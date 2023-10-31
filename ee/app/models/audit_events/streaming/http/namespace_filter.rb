# frozen_string_literal: true

module AuditEvents
  module Streaming
    module HTTP
      class NamespaceFilter < ApplicationRecord
        self.table_name = 'audit_events_streaming_http_group_namespace_filters'

        belongs_to :external_audit_event_destination, inverse_of: :namespace_filter
        belongs_to :namespace, inverse_of: :audit_event_http_namespace_filter

        validates :namespace, presence: true, uniqueness: true
        validates :external_audit_event_destination, presence: true, uniqueness: true

        validate :valid_destination_for_namespace,
          if: -> { namespace.present? && external_audit_event_destination.present? }

        validate :ensure_namespace_type, if: -> { namespace.present? }

        private

        def valid_destination_for_namespace
          return if namespace.root_ancestor == external_audit_event_destination.group

          errors.add(:external_audit_event_destination, 'does not belong to the top-level group of the namespace.')
        end

        def ensure_namespace_type
          return if namespace.is_a?(::Namespaces::ProjectNamespace) || namespace.is_a?(::Group)

          errors.add(:namespace, 'is not supported. Only project and group are supported.')
        end
      end
    end
  end
end
