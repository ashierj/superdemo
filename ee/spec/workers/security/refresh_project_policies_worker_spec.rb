# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Security::RefreshProjectPoliciesWorker, feature_category: :security_policy_management do
  let_it_be(:group) { create(:group) }
  let(:worker) { Security::ProcessScanResultPolicyWorker }
  let_it_be(:project) { create(:project, group: group) }
  let(:project_member_changed_event) do
    ::ProjectAuthorizations::AuthorizationsChangedEvent.new(data: { project_id: project.id })
  end

  let(:scan_result_policy) do
    build(
      :scan_result_policy,
      actions: [{ type: 'require_approval', approvals_required: 1, user_approvers_ids: [1] }]
    )
  end

  before do
    stub_licensed_features(security_orchestration_policies: true)
    stub_feature_flags(skip_refresh_project_policies: false)
  end

  it_behaves_like 'subscribes to event' do
    let(:event) { project_member_changed_event }

    it 'receives the event after some delay' do
      expect(described_class).to receive(:perform_in).with(1.minute, any_args)
      ::Gitlab::EventStore.publish(event)
    end
  end

  context 'when skip_refresh_project_policies is enabled' do
    before do
      stub_feature_flags(skip_refresh_project_policies: true)
    end

    it 'does not invoke Security::ProcessScanResultPolicyWorker' do
      expect(worker).not_to receive(:perform_async)

      consume_event(subscriber: described_class, event: project_member_changed_event)
    end
  end

  context 'when the project has a policy with user_approvers' do
    let_it_be(:configuration) { create(:security_orchestration_policy_configuration, project: project) }

    before do
      allow(configuration).to receive(:active_scan_result_policies).and_return([scan_result_policy])
      allow_next_found_instance_of(Project) do |instance|
        allow(instance).to receive(:all_security_orchestration_policy_configurations).and_return([configuration])
      end
    end

    it 'invokes Security::ProcessScanResultPolicyWorker' do
      expect(worker).to receive(:perform_in).with(0, project.id, configuration.id)

      consume_event(subscriber: described_class, event: project_member_changed_event)
    end
  end

  context 'when the project has multiple policy with user_approvers' do
    let_it_be(:inherited_configuration) do
      create(:security_orchestration_policy_configuration, project: nil, namespace: group)
    end

    let_it_be(:configuration) { create(:security_orchestration_policy_configuration, project: project) }

    before do
      allow(configuration).to receive(:active_scan_result_policies).and_return([scan_result_policy])
      allow(inherited_configuration).to receive(:active_scan_result_policies).and_return([scan_result_policy])

      allow_next_found_instance_of(Project) do |instance|
        allow(instance).to receive(:all_security_orchestration_policy_configurations).and_return([configuration,
          inherited_configuration])
      end
    end

    it 'invokes Security::ProcessScanResultPolicyWorker with incremental delay' do
      expect(worker).to receive(:perform_in).with(0, project.id, configuration.id).ordered
      expect(worker).to receive(:perform_in).with(30, project.id, inherited_configuration.id).ordered

      consume_event(subscriber: described_class, event: project_member_changed_event)
    end
  end

  context 'when the project has multiple policy but only one with user_approvers' do
    let_it_be(:inherited_configuration) do
      create(:security_orchestration_policy_configuration, project: nil, namespace: group)
    end

    let_it_be(:configuration) { create(:security_orchestration_policy_configuration, project: project) }

    before do
      allow(inherited_configuration).to receive(:active_scan_result_policies).and_return([scan_result_policy])

      allow_next_found_instance_of(Project) do |instance|
        allow(instance).to receive(:all_security_orchestration_policy_configurations).and_return([configuration,
          inherited_configuration])
      end
    end

    it 'invokes Security::ProcessScanResultPolicyWorker with incremental delay' do
      expect(worker).to receive(:perform_in).with(0, project.id, inherited_configuration.id)

      consume_event(subscriber: described_class, event: project_member_changed_event)
    end
  end
end
