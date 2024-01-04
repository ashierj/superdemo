# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ScanResultPolicies::AddApproversToRulesWorker, feature_category: :security_policy_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:project_id) { project.id }
  let(:user_ids) { [user.id] }
  let(:data) { { project_id: project_id, user_ids: user_ids } }
  let(:authorizations_event) { ProjectAuthorizations::AuthorizationsAddedEvent.new(data: data) }
  let(:licensed_feature) { true }

  before do
    stub_licensed_features(security_orchestration_policies: licensed_feature)
  end

  it_behaves_like 'subscribes to event' do
    let(:event) { authorizations_event }

    it 'calls Security::ScanResultPolicies::AddApproversToRulesService' do
      expect_next_instance_of(
        Security::ScanResultPolicies::AddApproversToRulesService,
        project: project
      ) do |service|
        expect(service).to receive(:execute).with([user.id])
      end

      consume_event(subscriber: described_class, event: authorizations_event)
    end
  end

  context 'when the project does not exist' do
    let(:project_id) { non_existing_record_id }

    it 'logs and does not call Security::ScanResultPolicies::AddApproversToRulesService' do
      expect(Sidekiq.logger).to receive(:info).with(
        hash_including('message' => 'Project not found.', 'project_id' => project_id)
      )
      expect(Security::ScanResultPolicies::AddApproversToRulesService).not_to receive(:new)

      expect { consume_event(subscriber: described_class, event: authorizations_event) }.not_to raise_exception
    end
  end

  context 'when the user_ids are empty' do
    let(:user_ids) { [] }

    it 'does not call Security::ScanResultPolicies::AddApproversToRulesService' do
      expect(Security::ScanResultPolicies::AddApproversToRulesService).not_to receive(:new)

      expect { consume_event(subscriber: described_class, event: authorizations_event) }.not_to raise_exception
    end
  end

  context 'when the feature flag "add_policy_approvers_to_rules" is disabled' do
    before do
      stub_feature_flags(add_policy_approvers_to_rules: false)
    end

    it 'does not call Security::ScanResultPolicies::AddApproversToRulesService' do
      expect(Security::ScanResultPolicies::AddApproversToRulesService).not_to receive(:new)

      expect { consume_event(subscriber: described_class, event: authorizations_event) }.not_to raise_exception
    end
  end

  context 'when the feature is not licensed' do
    let(:licensed_feature) { false }

    it 'does not call Security::ScanResultPolicies::AddApproversToRulesService' do
      expect(Security::ScanResultPolicies::AddApproversToRulesService).not_to receive(:new)

      expect { consume_event(subscriber: described_class, event: authorizations_event) }.not_to raise_exception
    end
  end
end
