# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::PersistSecurityPoliciesWorker, '#perform', feature_category: :security_policy_management do
  include_context 'with scan result policy' do
    let(:policy_configuration) { create(:security_orchestration_policy_configuration) }
    let(:scan_result_policies) { [build(:scan_result_policy), build(:scan_result_policy)] }

    it_behaves_like 'an idempotent worker' do
      subject(:perform) { perform_multiple(policy_configuration.id) }

      describe 'cache eviction' do
        let(:config) { spy }

        before do
          allow(Security::OrchestrationPolicyConfiguration)
            .to receive(:find_by_id).with(policy_configuration.id).and_return(config)

          allow(Gitlab::AppJsonLogger).to receive(:debug)
        end

        it 'evicts policy cache' do
          perform

          expect(config).to have_received(:invalidate_policy_yaml_cache).at_least(:once)
        end
      end

      it 'persists policies' do
        perform

        expect(policy_configuration.security_policies.count).to be(2)
      end
    end
  end
end
