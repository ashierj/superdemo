# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::UnenforceablePolicyRulesNotificationService, '#execute', feature_category: :security_policy_management do
  let_it_be(:project) { create(:project, :repository) }

  let(:service) { described_class.new(merge_request) }

  let_it_be_with_reload(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:pipeline) do
    create(:ee_ci_pipeline,
      :success,
      project: project,
      ref: merge_request.source_branch,
      sha: project.commit(merge_request.source_branch).sha,
      merge_requests_as_head_pipeline: [merge_request]
    )
  end

  let_it_be(:scan_result_policy_read) { create(:scan_result_policy_read, project: project) }
  let_it_be(:protected_branch) do
    create(:protected_branch, name: merge_request.target_branch, project: project)
  end

  subject(:execute) { service.execute }

  before do
    stub_licensed_features(security_orchestration_policies: true, dependency_scanning: true)
  end

  shared_examples_for 'triggers policy bot comment for both report types' do
    it 'enqueues Security::GeneratePolicyViolationCommentWorker for both report types' do
      %i[scan_finding license_scanning].each do |report_type|
        expect(Security::GeneratePolicyViolationCommentWorker).to receive(:perform_async).with(
          merge_request.id,
          { 'report_type' => Security::ScanResultPolicies::PolicyViolationComment::REPORT_TYPES[report_type],
            'violated_policy' => false,
            'requires_approval' => false }
        )
      end

      execute
    end
  end

  context 'without report approver rules' do
    it_behaves_like 'triggers policy bot comment for both report types'
  end

  context 'when all reports are enforceable' do
    before do
      create(:ee_ci_build, :sast, pipeline: pipeline, project: project)
      create(:ee_ci_build, :cyclonedx, pipeline: pipeline, project: pipeline.project)
    end

    it_behaves_like 'does not trigger policy bot comment'
  end

  context 'when merge request has no head pipeline' do
    before do
      merge_request.update!(head_pipeline: nil)
    end

    it_behaves_like 'triggers policy bot comment for both report types'
  end

  shared_examples_for 'unenforceable report' do |report_type|
    it_behaves_like 'triggers policy bot comment', report_type, false

    context 'with violated approval rules' do
      let(:approvals_required) { 1 }
      let!(:approval_project_rule) do
        create(:approval_project_rule, :any_merge_request, project: project, approvals_required: approvals_required,
          applies_to_all_protected_branches: true, protected_branches: [protected_branch],
          scan_result_policy_read: scan_result_policy_read)
      end

      before do
        create(:report_approver_rule, report_type, merge_request: merge_request,
          approval_project_rule: approval_project_rule, approvals_required: approvals_required,
          scan_result_policy_read: scan_result_policy_read)
        create(:scan_result_policy_violation, merge_request: merge_request,
          scan_result_policy_read: scan_result_policy_read, project: project)
      end

      it_behaves_like 'triggers policy bot comment', report_type, true

      context 'without required approvals' do
        let(:approvals_required) { 0 }

        it_behaves_like 'triggers policy bot comment', report_type, true, requires_approval: false
      end

      context 'when approval rules are not applicable to the target branch' do
        let_it_be(:policy_project) { create(:project, :repository) }
        let_it_be(:policy_configuration) do
          create(:security_orchestration_policy_configuration,
            project: project,
            security_policy_management_project: policy_project)
        end

        let(:scan_result_policy) { build(:scan_result_policy, :any_merge_request, branches: ['protected']) }
        let(:policy_yaml) do
          build(:orchestration_policy_yaml, scan_result_policy: [scan_result_policy])
        end

        before do
          merge_request.update!(target_branch: 'non-protected')
          allow_next_instance_of(Repository) do |repository|
            allow(repository).to receive(:blob_data_at).and_return(policy_yaml)
          end
        end

        it_behaves_like 'triggers policy bot comment', report_type, false
      end
    end
  end

  context 'with unenforceable scan_finding report' do
    before do
      create(:ee_ci_build, :cyclonedx, pipeline: pipeline, project: pipeline.project)
    end

    it_behaves_like 'unenforceable report', :scan_finding
  end

  context 'with unenforceable license_scanning report' do
    before do
      create(:ee_ci_build, :sast, pipeline: pipeline, project: project)
    end

    it_behaves_like 'unenforceable report', :license_scanning
  end
end
