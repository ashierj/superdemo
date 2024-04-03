# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::AiTracking, feature_category: :value_stream_management do
  describe '.track_event', :freeze_time do
    subject(:track_event) { described_class.track_event(event_name, event_context) }

    let(:event_context) { { user_id: 1, language: 'ruby' } }
    let(:event_name) { 'code_suggestions_requested' }

    it 'writes to ClickHouse buffer with event data' do
      expect(::ClickHouse::WriteBuffer)
        .to receive(:write_event).with(event_context.merge(event: 1, timestamp: Time.zone.now)).once

      track_event
    end

    context 'when :ai_tracking_data_gathering feature flag is disabled' do
      before do
        stub_feature_flags(ai_tracking_data_gathering: false)
      end

      it 'does not write to ClickHouse buffer' do
        expect(::ClickHouse::WriteBuffer).not_to receive(:write_event)

        track_event
      end
    end
  end
end
