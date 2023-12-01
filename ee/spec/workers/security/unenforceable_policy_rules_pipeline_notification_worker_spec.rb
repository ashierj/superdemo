# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::UnenforceablePolicyRulesPipelineNotificationWorker, feature_category: :security_policy_management do
  let_it_be(:pipeline) { create(:ci_empty_pipeline) }
  let_it_be(:project) { pipeline.project }
  let_it_be(:merge_request) { create(:ee_merge_request, head_pipeline: pipeline) }
  let_it_be(:other_merge_request) { create(:ee_merge_request) }
  let(:feature_licensed) { true }
  let_it_be(:scan_result_policy_read) { create(:scan_result_policy_read, project: project) }
  let!(:approval_project_rule) do
    create(:approval_project_rule, :scan_finding, project: project, scan_result_policy_read: scan_result_policy_read)
  end

  before do
    stub_licensed_features(security_orchestration_policies: feature_licensed)
  end

  describe '#perform' do
    subject(:run_worker) { described_class.new.perform(pipeline_id) }

    let(:pipeline_id) { pipeline.id }

    it 'calls UnenforceablePolicyRulesNotificationService' do
      expect_next_instance_of(Security::UnenforceablePolicyRulesNotificationService, merge_request) do |instance|
        expect(instance).to receive(:execute)
      end

      run_worker
    end

    context 'when pipeline does not exist' do
      let(:pipeline_id) { non_existing_record_id }

      it 'does not call UnenforceablePolicyRulesNotificationService' do
        expect(Security::UnenforceablePolicyRulesNotificationService).not_to receive(:new)

        run_worker
      end
    end

    context 'when feature is not licensed' do
      let(:feature_licensed) { false }

      it 'does not call UnenforceablePolicyRulesNotificationService' do
        expect(Security::UnenforceablePolicyRulesNotificationService).not_to receive(:new)

        run_worker
      end
    end

    context 'when there are no approval rules with scan result policy reads' do
      let!(:approval_project_rule) { nil }

      it 'does not call UnenforceablePolicyRulesNotificationService' do
        expect(Security::UnenforceablePolicyRulesNotificationService).not_to receive(:new)

        run_worker
      end
    end

    context 'when the pipeline has all security policies reports' do
      before do
        pipeline_double = instance_double(Ci::Pipeline, has_all_security_policies_reports?: true)
        allow(Ci::Pipeline).to receive(:find_by_id).with(pipeline_id).and_return(pipeline_double)
      end

      it 'does not call UnenforceablePolicyRulesNotificationService' do
        expect(Security::UnenforceablePolicyRulesNotificationService).not_to receive(:new)

        run_worker
      end
    end

    context 'when feature flag "security_policies_unenforceable_rules_notification" is disabled' do
      before do
        stub_feature_flags(security_policies_unenforceable_rules_notification: false)
      end

      it 'does not call UnenforceablePolicyRulesNotificationService' do
        expect(Security::UnenforceablePolicyRulesNotificationService).not_to receive(:new)

        run_worker
      end
    end
  end
end
