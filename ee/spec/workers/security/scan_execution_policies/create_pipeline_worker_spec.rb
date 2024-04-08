# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ScanExecutionPolicies::CreatePipelineWorker, feature_category: :security_policy_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:security_orchestration_policy_configuration) do
    create(:security_orchestration_policy_configuration, project: project)
  end

  let_it_be(:schedule) do
    create(:security_orchestration_policy_rule_schedule,
      security_orchestration_policy_configuration: security_orchestration_policy_configuration)
  end

  let(:project_id) { project.id }
  let(:current_user_id) { current_user.id }
  let(:branch) { 'production' }
  let(:actions) { [{ scan: 'dast' }] }
  let(:params) { { actions: actions, branch: branch } }
  let(:schedule_id) { schedule.id }
  let(:policy) { build(:scan_execution_policy, enabled: true, actions: [{ scan: 'dast' }]) }

  shared_examples_for 'does not call RuleScheduleService' do
    it do
      expect(Security::SecurityOrchestrationPolicies::RuleScheduleService).not_to receive(:new)

      run_worker
    end
  end

  describe '#perform' do
    before do
      allow_next_found_instance_of(Security::OrchestrationPolicyConfiguration) do |instance|
        allow(instance).to receive(:active_scan_execution_policies).and_return([policy])
      end
    end

    subject(:run_worker) { described_class.new.perform(project_id, current_user_id, schedule_id, branch) }

    context 'when project is not found' do
      let(:project_id) { non_existing_record_id }

      it_behaves_like 'does not call RuleScheduleService'
    end

    context 'when user is not found' do
      let(:current_user_id) { non_existing_record_id }

      it_behaves_like 'does not call RuleScheduleService'
    end

    context 'when the user and project exists' do
      it 'delegates the pipeline creation to Security::SecurityOrchestrationPolicies::CreatePipelineService' do
        expect(::Security::SecurityOrchestrationPolicies::CreatePipelineService).to(
          receive(:new)
            .with(project: project, current_user: current_user, params: params)
            .and_call_original)

        run_worker
      end

      context 'when create pipeline service returns errors' do
        before do
          allow_next_instance_of(::Security::SecurityOrchestrationPolicies::CreatePipelineService) do |service|
            allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'message'))
          end
        end

        it 'logs the error' do
          expect(::Gitlab::AppJsonLogger).to receive(:warn).with({
            'class' => 'Security::ScanExecutionPolicies::CreatePipelineWorker',
            'security_orchestration_policy_configuration_id' => security_orchestration_policy_configuration.id,
            'user_id' => current_user.id,
            'message' => 'message'
          })
          run_worker
        end
      end
    end
  end
end
