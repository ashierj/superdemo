# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees security policy with scan finding rule',
  :js, :sidekiq_inline, :use_clean_rails_memory_store_caching,
  feature_category: :security_policy_management do
  include Features::SecurityPolicyHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.creator }
  let(:policy_management_project) { create(:project, :repository, creator: user, namespace: project.namespace) }
  let(:mr_params) do
    {
      title: 'MR to test scan result policy',
      target_branch: project.default_branch,
      source_branch: 'feature'
    }
  end

  let(:merge_request) do
    ::MergeRequests::CreateService.new(project: project,
      current_user: user,
      params: mr_params).execute
  end

  let(:merge_request_path) { project_merge_request_path(project, merge_request) }

  let_it_be(:approver) { create(:user) }
  let_it_be(:approver_roles) { ['maintainer'] }
  let!(:protected_branch) { create(:protected_branch, project: project, name: merge_request.target_branch) }
  let!(:pipeline) { nil }
  let(:policy_rule) do
    {
      type: 'scan_finding',
      scanners: scanners,
      vulnerabilities_allowed: 0,
      severity_levels: [],
      vulnerability_states: [],
      branches: %w[master]
    }
  end

  before_all do
    project.add_developer(user)
    project.add_maintainer(approver)
  end

  context 'with scan findings' do
    let(:policy_name) { "Spooky_policy" }
    let!(:pipeline_scan) do
      create(:security_scan, :succeeded, project: project, pipeline: pipeline, scan_type: 'sast')
    end

    let!(:sast_finding) { create(:security_finding, severity: 'high', scan: pipeline_scan) }
    let(:is_scan_finding_rule) { true }
    let!(:pipeline) do
      create(:ee_ci_pipeline, :success, :with_sast_report, merge_requests_as_head_pipeline: [merge_request],
        project: project, ref: merge_request.source_branch, sha: merge_request.diff_head_sha).tap do |p|
        pipeline_scan = create(:security_scan, :succeeded, project: project, pipeline: p, scan_type: 'sast')
        create(:security_finding, severity: 'high', scan: pipeline_scan)
      end
    end

    before do
      sign_in(user)
    end

    context 'when scanner from pipeline matches the policy' do
      let(:scanners) { %w[sast] }

      before do
        create_policy_setup
      end

      it 'blocks the MR' do
        visit(merge_request_path)
        wait_for_requests
        expect(page).to have_content 'Merge blocked'
      end
    end

    context 'when scanner from pipeline does not match the policy' do
      let(:scanners) { %w[dast] }

      before do
        create_policy_setup
      end

      it 'does not block the MR' do
        visit(merge_request_path)
        wait_for_requests
        expect(page).not_to have_content 'Merge blocked'
        expect(page).to have_button('Merge', exact: true)
      end
    end
  end
end
