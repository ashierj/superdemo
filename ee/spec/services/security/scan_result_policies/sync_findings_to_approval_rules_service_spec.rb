# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ScanResultPolicies::SyncFindingsToApprovalRulesService, feature_category: :security_policy_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be_with_refind(:merge_request) { create(:merge_request, source_project: project) }

  let_it_be(:target_pipeline) { create(:ee_ci_pipeline, project: project, ref: merge_request.target_branch) }
  let_it_be(:pipeline) do
    create(:ee_ci_pipeline,
      project: project,
      ref: merge_request.source_branch,
      sha: project.commit(merge_request.source_branch).sha,
      merge_requests_as_head_pipeline: [merge_request]
    )
  end

  shared_examples 'updates approvals' do
    it do
      expect(Security::ScanResultPolicies::SyncMergeRequestApprovalsWorker).to receive(:perform_async).with(
        pipeline.id,
        merge_request.id
      ).and_call_original

      execute
    end
  end

  shared_examples 'does not update approvals' do
    it do
      expect(Security::ScanResultPolicies::SyncMergeRequestApprovalsWorker).not_to receive(:perform_async)

      execute
    end
  end

  describe '#execute' do
    subject(:execute) { described_class.new(pipeline).execute }

    context 'when pipeline_findings is empty' do
      it_behaves_like 'does not update approvals'
    end

    context 'when pipeline is not complete' do
      let_it_be(:pipeline) { create(:ee_ci_pipeline, :running, project: project) }

      it_behaves_like 'does not update approvals'
    end

    context 'when pipeline source is not one of ci_and_security_orchestration_sources' do
      let_it_be(:pipeline) { create(:ee_ci_pipeline, :success, project: project, source: :parent_pipeline) }

      it_behaves_like 'does not update approvals'
    end

    context 'when pipeline_findings is not empty' do
      let_it_be(:pipeline_scan) { create(:security_scan, pipeline: pipeline) }
      let_it_be(:pipeline_findings) do
        create(:security_finding, scan: pipeline_scan, severity: 'high')
      end

      it_behaves_like 'updates approvals'

      context 'when merge_request is closed' do
        before do
          merge_request.update!(state_id: MergeRequest.available_states[:closed])
        end

        it_behaves_like 'does not update approvals'
      end

      context 'when pipeline is not latest' do
        let_it_be(:pipeline) do
          create(:ee_ci_pipeline, project: project, ref: merge_request.source_branch)
        end

        it_behaves_like 'does not update approvals'
      end

      context 'with merge request targeting pipeline ref' do
        let_it_be(:other_merge_request) do
          create(
            :merge_request,
            source_project: project,
            target_branch: merge_request.source_branch,
            source_branch: "feature")
        end

        let_it_be(:other_pipeline) do
          create(
            :ee_ci_pipeline,
            project: project,
            ref: other_merge_request.source_branch,
            sha: project.commit(other_merge_request.source_branch).sha,
            merge_requests_as_head_pipeline: [other_merge_request])
        end

        it 'updates approvals for merge requests targeting the source branch' do
          expect(Security::ScanResultPolicies::SyncMergeRequestApprovalsWorker).to receive(:perform_async).with(
            pipeline.id,
            merge_request.id
          ).and_call_original.ordered

          expect(Security::ScanResultPolicies::SyncMergeRequestApprovalsWorker).to receive(:perform_async).with(
            other_pipeline.id,
            other_merge_request.id
          ).and_call_original.ordered

          execute
        end
      end
    end
  end
end
