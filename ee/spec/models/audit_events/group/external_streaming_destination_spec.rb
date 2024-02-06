# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Group::ExternalStreamingDestination, feature_category: :audit_events do
  subject(:destination) { build(:audit_events_group_external_streaming_destination) }

  describe 'Associations' do
    it 'belongs to a group' do
      expect(destination.group).not_to be_nil
    end
  end

  describe 'Validations' do
    let_it_be(:group) { create(:group) }

    it 'validates uniqueness of name scoped to namespace' do
      create(:audit_events_group_external_streaming_destination, name: 'Test Destination', group: group)
      destination = build(:audit_events_group_external_streaming_destination, name: 'Test Destination', group: group)

      expect(destination).not_to be_valid
      expect(destination.errors.full_messages).to include('Name has already been taken')
    end

    context 'when group' do
      it 'is a subgroup' do
        destination.group = build(:group, :nested)

        expect(destination).to be_invalid
        expect(destination.errors.full_messages).to include('Group must not be a subgroup. Use a top-level group.')
      end
    end
  end

  it_behaves_like 'includes Limitable concern' do
    subject { build(:audit_events_group_external_streaming_destination) }
  end

  it_behaves_like 'includes ExternallyStreamable concern' do
    subject { build(:audit_events_group_external_streaming_destination) }

    let(:model_factory_name) { :audit_events_group_external_streaming_destination }
  end
end
