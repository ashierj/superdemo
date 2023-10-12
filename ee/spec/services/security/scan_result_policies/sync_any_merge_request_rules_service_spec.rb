# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ScanResultPolicies::SyncAnyMergeRequestRulesService, feature_category: :security_policy_management do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project, :repository) }
  let(:service) { described_class.new(merge_request) }
  let_it_be(:merge_request, reload: true) { create(:ee_merge_request, source_project: project) }

  before do
    stub_licensed_features(security_orchestration_policies: true)
  end

  describe '#execute' do
    subject(:execute) { service.execute }

    let(:approvals_required) { 1 }
    let(:signed_commit) { instance_double(Commit, has_signature?: true) }
    let(:unsigned_commit) { instance_double(Commit, has_signature?: false) }
    let_it_be(:scan_result_policy_read, reload: true) do
      create(:scan_result_policy_read, project: project)
    end

    let!(:approval_project_rule) do
      create(:approval_project_rule, :any_merge_request, project: project, approvals_required: approvals_required,
        scan_result_policy_read: scan_result_policy_read)
    end

    let!(:approver_rule) do
      create(:report_approver_rule, :any_merge_request, merge_request: merge_request,
        approval_project_rule: approval_project_rule, approvals_required: approvals_required,
        scan_result_policy_read: scan_result_policy_read)
    end

    shared_examples_for 'does not update approval rules' do
      it 'does not update approval rules' do
        expect { execute }.not_to change { approver_rule.reload.approvals_required }
      end
    end

    shared_examples_for 'sets approvals_required to 0' do
      it 'sets approvals_required to 0' do
        expect { execute }.to change { approver_rule.reload.approvals_required }.to(0)
      end
    end

    context 'when merge_request is merged' do
      before do
        merge_request.update!(state: 'merged')
      end

      it_behaves_like 'does not update approval rules'
      it_behaves_like 'does not trigger policy bot comment'
    end

    context 'without violations' do
      context 'when policy does not target any commit' do
        it_behaves_like 'sets approvals_required to 0'
        it_behaves_like 'triggers policy bot comment', :any_merge_request, false
      end

      context 'when policy targets unsigned commits and there are only signed commits in merge request' do
        before do
          scan_result_policy_read.update!(commits: :unsigned)
          allow(merge_request).to receive(:commits).and_return([signed_commit])
        end

        it_behaves_like 'sets approvals_required to 0'
        it_behaves_like 'triggers policy bot comment', :any_merge_request, false

        it 'creates no violation records' do
          expect { execute }.not_to change { merge_request.scan_result_policy_violations.count }
        end

        it 'does not create a log' do
          expect(Gitlab::AppJsonLogger).not_to receive(:info)

          execute
        end
      end
    end

    context 'with violations' do
      let(:policy_commits) { :any }
      let(:merge_request_commits) { [unsigned_commit] }

      before do
        scan_result_policy_read.update!(commits: policy_commits)
        allow(merge_request).to receive(:commits).and_return(merge_request_commits)
      end

      context 'when approvals are optional' do
        let(:approvals_required) { 0 }

        it_behaves_like 'does not update approval rules'
        it_behaves_like 'triggers policy bot comment', :any_merge_request, true, requires_approval: false
      end

      context 'when approval are required but approval_merge_request_rules have been made optional' do
        let!(:approval_project_rule) do
          create(:approval_project_rule, :any_merge_request, project: project, approvals_required: 1,
            scan_result_policy_read: scan_result_policy_read)
        end

        let!(:approver_rule) do
          create(:report_approver_rule, :any_merge_request, merge_request: merge_request,
            approval_project_rule: approval_project_rule, approvals_required: 0,
            scan_result_policy_read: scan_result_policy_read)
        end

        it 'resets the required approvals' do
          expect { execute }.to change { approver_rule.reload.approvals_required }.to(1)
        end

        it_behaves_like 'triggers policy bot comment', :any_merge_request, true
      end

      where(:policy_commits, :merge_request_commits) do
        :unsigned | [ref(:unsigned_commit)]
        :unsigned | [ref(:signed_commit), ref(:unsigned_commit)]
        :any      | [ref(:signed_commit)]
        :any      | [ref(:unsigned_commit)]
      end

      with_them do
        it_behaves_like 'does not update approval rules'
        it_behaves_like 'triggers policy bot comment', :any_merge_request, true

        it 'creates violation records' do
          expect { execute }.to change { merge_request.scan_result_policy_violations.count }.by(1)
        end

        it 'logs violated rules' do
          expect(Gitlab::AppJsonLogger).to receive(:info).with(hash_including(message: 'Updating MR approval rule'))

          execute
        end
      end
    end
  end
end
