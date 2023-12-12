# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::EventStore, feature_category: :shared do
  describe '.instance' do
    it 'returns a store with CE and EE subscriptions' do
      instance = described_class.instance

      expect(instance.subscriptions.keys).to include(
        ::Ci::JobArtifactsDeletedEvent,
        ::Ci::PipelineCreatedEvent,
        ::Repositories::KeepAroundRefsCreatedEvent,
        ::MergeRequests::ApprovedEvent,
        ::MergeRequests::DraftStateChangeEvent,
        ::MergeRequests::UnblockedStateEvent,
        ::GitlabSubscriptions::RenewedEvent,
        ::Repositories::DefaultBranchChangedEvent,
        ::NamespaceSettings::AiRelatedSettingsChangedEvent,
        ::Members::MembersAddedEvent,
        ::ProjectAuthorizations::AuthorizationsChangedEvent,
        ::ProjectAuthorizations::AuthorizationsRemovedEvent,
        ::Projects::ComplianceFrameworkChangedEvent
      )
    end
  end

  describe '.publish_group' do
    let(:events) { [] }

    it 'calls publish_group of instance' do
      expect(described_class.instance).to receive(:publish_group).with(events)

      described_class.publish_group(events)
    end
  end
end
