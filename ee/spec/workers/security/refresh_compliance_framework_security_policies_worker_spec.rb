# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Security::RefreshComplianceFrameworkSecurityPoliciesWorker, feature_category: :security_policy_management do
  let_it_be(:root_namespace) { create(:group) }
  let_it_be(:namespace) { create(:group, parent: root_namespace) }
  let_it_be(:other_namespace) { create(:group, parent: root_namespace) }
  let_it_be(:project) { create(:project, namespace: namespace) }
  let_it_be(:project_policy_configuration) { create(:security_orchestration_policy_configuration, project: project) }
  let_it_be(:policy_configuration) do
    create(:security_orchestration_policy_configuration, project: nil, namespace: namespace)
  end

  let_it_be(:other_policy_configuration) do
    create(:security_orchestration_policy_configuration, project: nil, namespace: other_namespace)
  end

  let_it_be(:compliance_framework) { create(:compliance_framework, namespace: root_namespace) }
  let_it_be(:compliance_framework_security_policy) do
    create(:compliance_framework_security_policy,
      policy_configuration: policy_configuration,
      framework: compliance_framework
    )
  end

  let_it_be(:project_compliance_framework_security_policy) do
    create(:compliance_framework_security_policy,
      policy_configuration: project_policy_configuration,
      framework: compliance_framework
    )
  end

  let(:compliance_framework_changed_event) do
    ::Projects::ComplianceFrameworkChangedEvent.new(data: {
      project_id: project.id,
      compliance_framework_id: compliance_framework.id,
      event_type: ::Projects::ComplianceFrameworkChangedEvent::EVENT_TYPES[:added]
    })
  end

  before do
    allow_next_found_instance_of(Security::OrchestrationPolicyConfiguration) do |configuration|
      allow(configuration).to receive(:policy_configuration_valid?).and_return(true)
    end
  end

  it_behaves_like 'subscribes to event' do
    let(:event) { compliance_framework_changed_event }

    it 'receives the event' do
      expect(described_class).to receive(:perform_async).with('Projects::ComplianceFrameworkChangedEvent',
        compliance_framework_changed_event.data.deep_stringify_keys)
      ::Gitlab::EventStore.publish(event)
    end
  end

  context 'when feature flag is enabled' do
    it 'invokes Security::ProcessScanResultPolicyWorker with the project_id and configuration_id' do
      expect(Security::ProcessScanResultPolicyWorker).to receive(:perform_async).once.with(project.id,
        policy_configuration.id)
      expect(Security::ProcessScanResultPolicyWorker).not_to receive(:perform_async).with(project.id,
        project_policy_configuration.id)
      expect(Security::ProcessScanResultPolicyWorker).not_to receive(:perform_async).with(project.id,
        other_policy_configuration.id)

      consume_event(subscriber: described_class, event: compliance_framework_changed_event)
    end
  end

  context 'when feature flag is disabled' do
    before do
      stub_feature_flags(security_policies_policy_scope: false)
    end

    it 'does not invoke Security::ProcessScanResultPolicyWorker' do
      consume_event(subscriber: described_class, event: compliance_framework_changed_event)

      expect(Security::ProcessScanResultPolicyWorker).not_to receive(:perform_async)
    end
  end
end
