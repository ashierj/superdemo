# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Instance::ExternalStreamingDestination, feature_category: :audit_events do
  subject(:destination) { build(:audit_events_instance_external_streaming_destination) }

  describe 'Validations' do
    it 'validates uniqueness of name scoped to namespace' do
      create(:audit_events_instance_external_streaming_destination, name: 'Test Destination')
      destination = build(:audit_events_instance_external_streaming_destination, name: 'Test Destination')

      expect(destination).not_to be_valid
      expect(destination.errors.full_messages).to include('Name has already been taken')
    end
  end

  it_behaves_like 'includes Limitable concern' do
    subject { build(:audit_events_instance_external_streaming_destination) }
  end

  it_behaves_like 'includes ExternallyStreamable concern' do
    subject { build(:audit_events_instance_external_streaming_destination) }

    let(:model_factory_name) { :audit_events_instance_external_streaming_destination }
  end
end
