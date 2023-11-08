# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComplianceManagement::ComplianceFramework::SecurityPolicy, feature_category: :security_policy_management do
  describe 'Associations' do
    subject { create(:compliance_framework_security_policy) }

    it 'belongs to compliance framework and security_orchestration_policy_configuration' do
      expect(subject).to belong_to(:framework)
      expect(subject).to belong_to(:policy_configuration)
    end
  end

  describe 'validations' do
    subject { create(:compliance_framework_security_policy) }

    it { is_expected.to validate_uniqueness_of(:framework).scoped_to([:policy_configuration_id, :policy_index]) }
  end

  describe '.for_framework' do
    let_it_be(:framework_1) { create(:compliance_framework) }
    let_it_be(:framework_2) { create(:compliance_framework) }
    let_it_be(:policy_1) { create(:compliance_framework_security_policy, framework: framework_1) }
    let_it_be(:policy_2) { create(:compliance_framework_security_policy, framework: framework_2) }

    subject { described_class.for_framework(framework_1) }

    it { is_expected.to eq([policy_1]) }
  end

  describe '.for_policy_configuration' do
    let_it_be(:policy_configuration_1) { create(:security_orchestration_policy_configuration) }
    let_it_be(:policy_configuration_2) { create(:security_orchestration_policy_configuration) }
    let_it_be(:policy_1) { create(:compliance_framework_security_policy, policy_configuration: policy_configuration_1) }
    let_it_be(:policy_2) { create(:compliance_framework_security_policy, policy_configuration: policy_configuration_2) }

    subject { described_class.for_policy_configuration(policy_configuration_1) }

    it { is_expected.to eq([policy_1]) }
  end
end
