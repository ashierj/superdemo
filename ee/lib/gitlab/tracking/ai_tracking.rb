# frozen_string_literal: true

module Gitlab
  module Tracking
    module AiTracking
      EVENTS = {
        'code_suggestions_requested' => 1
      }.freeze

      class << self
        def track_event(event_name, context_hash = {})
          return unless Feature.enabled?(:ai_tracking_data_gathering)
          return unless Gitlab::ClickHouse.globally_enabled_for_analytics?

          ::ClickHouse::WriteBuffer.write_event(context_hash.merge(event: EVENTS[event_name], timestamp: Time.zone.now))
        end
      end
    end
  end
end
