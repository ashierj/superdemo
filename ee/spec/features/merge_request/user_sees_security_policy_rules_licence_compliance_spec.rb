# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees security policy rules license compliance',
  :js, :sidekiq_inline, :use_clean_rails_memory_store_caching,
  feature_category: :security_policy_management do
  let_it_be(:project) { create(:project, :repository) }
  let(:policy_management_project) { create(:project, :repository, creator: user, namespace: project.namespace) }
  let_it_be(:user) { create(:user) }
  let_it_be(:approver) { create(:user) }

  before_all do
    project.add_developer(user)
    project.add_maintainer(approver)
  end

  before do
    sign_in(user)
  end

  context 'with license compliance' do
    let_it_be(:ee_merge_request) do
      create(:ee_merge_request, :with_cyclonedx_reports, source_project: project,
        source_branch: 'feature', target_branch: 'master')
    end

    let(:ee_merge_request_path) { project_merge_request_path(project, ee_merge_request) }

    shared_examples 'a merge request without violations' do
      it 'does not block the MR' do
        visit(ee_merge_request_path)
        wait_for_requests

        expect(page).not_to have_content 'Policy violation(s) detected'
        expect(page).to have_content 'Ready to merge!'
        expect(page).to have_button('Merge', exact: true)
      end
    end

    shared_examples 'with scan result policy' do
      let!(:existing_license) { create(:pm_license, spdx_identifier: 'MIT') }
      let!(:package) do
        create(:pm_package, name: "activesupport", purl_type: "gem",
          other_licenses: [{ license_names: ["MIT"], versions: ["5.1.4"] }])
      end

      before do
        stub_feature_flags(merge_when_checks_pass: false)
        stub_licensed_features(security_dashboard: true,
          license_scanning: true,
          security_orchestration_policies: true)
        policy_management_project.add_developer(user)

        create(:security_orchestration_policy_configuration,
          security_policy_management_project: policy_management_project,
          project: project)

        policy_update_branch_name = create_policy_update_branch

        merge_policy_mr(policy_update_branch_name)
      end

      context 'when scan result policy for license scanning is not violated' do
        let(:license_type) { 'Apache-2.0' }

        it_behaves_like 'a merge request without violations'
      end

      context 'when scan result policy for license scanning is violated' do
        let(:license_type) { 'MIT' }

        it 'requires approval', :aggregate_failures do
          visit(ee_merge_request_path)
          wait_for_requests

          expect(page).to have_content 'Requires 1 approval from eligible users'
          expect(page).to have_content 'Policy violation(s) detected'
          expect(page).to have_content 'Merge blocked'
          expect(page).not_to have_button('Merge', exact: true)
        end
      end
    end

    context 'when license scanning feature is not enabled' do
      before do
        stub_licensed_features(license_scanning: false)
      end

      it_behaves_like 'a merge request without violations'
    end

    context 'when license scanning feature is enabled' do
      before do
        stub_licensed_features(license_scanning: true)
      end

      it_behaves_like 'a merge request without violations'
      it_behaves_like 'with scan result policy'
    end
  end

  def create_policy_update_branch
    rule = {
      type: 'license_finding',
      branches: %w[master],
      match_on_inclusion: true,
      license_types: [license_type],
      license_states: %w[newly_detected]
    }

    policy_name = "Deny #{license_type} licenses"
    policy_hash = build(:scan_result_policy, name: policy_name,
      actions: [{ type: 'require_approval', approvals_required: 1,
                  user_approvers_ids: [approver.id] }], rules: [rule])

    input_policy_yaml = policy_hash.merge(type: 'scan_result_policy').to_yaml
    params = { policy_yaml: input_policy_yaml, name: policy_name, operation: :append }
    service = Security::SecurityOrchestrationPolicies::PolicyCommitService.new(container: project,
      current_user: user,
      params: params)
    response = service.execute

    response[:branch]
  end

  def merge_policy_mr(policy_update_branch_name)
    mr_params = {
      title: 'Add policy file',
      target_branch: policy_management_project.default_branch,
      source_branch: policy_update_branch_name
    }

    policy_merge_request = ::MergeRequests::CreateService.new(project: policy_management_project,
      current_user: user,
      params: mr_params).execute

    merge_params = { commit_message: 'Merge commit message',
                     squash_commit_message: 'Squash commit message',
                     sha: policy_merge_request.diff_head_sha }

    policy_merge_request.merge_async(user.id, merge_params)
  end
end
