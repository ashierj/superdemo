# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SyncLicenseScanningRulesService, feature_category: :security_policy_management do
  let_it_be(:project) { create(:project, :public, :repository) }
  let(:service) { described_class.new(pipeline) }

  let_it_be_with_refind(:merge_request) do
    create(:merge_request, :with_merge_request_pipeline, source_project: project)
  end

  let_it_be_with_reload(:pipeline) do
    create(
      :ee_ci_pipeline,
      :success,
      :with_cyclonedx_report,
      project: project,
      merge_requests_as_head_pipeline: [merge_request],
      ref: merge_request.target_branch,
      sha: merge_request.diff_base_sha,
      target_sha: merge_request.target_branch_sha)
  end

  let(:license_report) { ::Gitlab::LicenseScanning.scanner_for_pipeline(project, pipeline).report }
  let!(:ee_ci_build) { create(:ee_ci_build, :success, :license_scanning, pipeline: pipeline, project: project) }

  before do
    stub_licensed_features(license_scanning: true)
  end

  describe '#execute' do
    subject(:execute) { service.execute }

    context 'when license_report is empty' do
      let!(:license_compliance_rule) do
        create(:report_approver_rule, :license_scanning, merge_request: merge_request, approvals_required: 1)
      end

      before do
        pipeline.update_attribute(:status, :pending)
      end

      it 'does not update approval rules' do
        expect { execute }.not_to change { license_compliance_rule.reload.approvals_required }
      end

      it 'does not call report' do
        allow_any_instance_of(Gitlab::Ci::Reports::LicenseScanning::Report) do |instance|
          expect(instance).not_to receive(:violates?)
        end

        execute
      end

      it 'does not generate policy violation comment' do
        expect(Security::GeneratePolicyViolationCommentWorker).not_to receive(:perform_async)

        execute
      end
    end

    context 'with license_finding security policy' do
      let(:license_states) { ['newly_detected'] }
      let(:match_on_inclusion_license) { true }
      let(:approvals_required) { 1 }
      let_it_be(:protected_branch) do
        create(:protected_branch, name: merge_request.target_branch, project: project)
      end

      let(:scan_result_policy_read) do
        create(:scan_result_policy_read, license_states: license_states,
          match_on_inclusion_license: match_on_inclusion_license)
      end

      let!(:license_finding_project_rule) do
        create(:approval_project_rule, :license_scanning, project: project,
          approvals_required: approvals_required, scan_result_policy_read: scan_result_policy_read,
          protected_branches: [protected_branch])
      end

      let!(:license_finding_rule) do
        create(:report_approver_rule, :license_scanning, merge_request: merge_request,
          approval_project_rule: license_finding_project_rule,
          approvals_required: approvals_required, scan_result_policy_read: scan_result_policy_read)
      end

      let(:sbom_scanner) { instance_double('Gitlab::LicenseScanning::SbomScanner', report: target_branch_report) }
      let(:target_branch_report) { create(:ci_reports_license_scanning_report) }

      let(:case5) do
        [
          ['GPL v3', 'GNU 3', 'A'],
          ['MIT', 'MIT License', 'B'],
          ['GPL v3', 'GNU 3', 'C'],
          ['Apache 2', 'Apache License 2', 'D']
        ]
      end

      let(:case4) { [['GPL v3', 'GNU 3', 'A'], ['MIT', 'MIT License', 'B'], ['GPL v3', 'GNU 3', 'C']] }
      let(:case3) { [['GPL v3', 'GNU 3', 'A'], ['MIT', 'MIT License', 'B']] }
      let(:case2) { [['GPL v3', 'GNU 3', 'A']] }
      let(:case1) { [] }

      context 'when target branch pipeline is empty' do
        it 'does not require approval' do
          expect { execute }.to change { license_finding_rule.reload.approvals_required }.from(1).to(0)
        end
      end

      it_behaves_like 'triggers policy bot comment', :license_scanning, false
      it_behaves_like 'merge request without scan result violations'

      context 'with violations' do
        let(:license) { create(:software_license, name: 'GPL v3') }
        let(:pipeline_report) { create(:ci_reports_license_scanning_report) }

        before do
          pipeline_report.add_license(id: nil, name: 'GPL v3').add_dependency(name: 'A')

          create(:software_license_policy, :denied, project: project, software_license: license,
            scan_result_policy_read: scan_result_policy_read)

          allow(service).to receive(:report).and_return(pipeline_report)

          allow(::Gitlab::LicenseScanning).to receive(:scanner_for_pipeline).with(project,
            pipeline).and_return(sbom_scanner)
        end

        it_behaves_like 'triggers policy bot comment', :license_scanning, true
        it_behaves_like 'merge request with scan result violations'

        context 'when no approvals are required' do
          let(:approvals_required) { 0 }

          it_behaves_like 'triggers policy bot comment', :license_scanning, true, requires_approval: false
        end

        context 'when targeting an unprotected branch' do
          before do
            merge_request.update!(target_branch: 'non-protected')
            pipeline.update!(ref: 'non-protected')
          end

          it_behaves_like 'triggers policy bot comment', :license_scanning, false, requires_approval: false
        end

        context 'when most recent base pipeline lacks SBOM report' do
          let(:pipeline_without_sbom) do
            create(
              :ee_ci_pipeline,
              :success,
              source: :security_orchestration_policy,
              project: project,
              ref: merge_request.target_branch,
              sha: merge_request.diff_base_sha)
          end

          it_behaves_like 'triggers policy bot comment', :license_scanning, true, requires_approval: true
        end

        context 'with merge base pipeline and SBOM report present' do
          let_it_be(:pipeline) do
            create(
              :ee_ci_pipeline,
              :success,
              :with_cyclonedx_report,
              project: project,
              merge_requests_as_head_pipeline: [merge_request],
              ref: merge_request.target_branch,
              sha: merge_request.diff_head_sha,
              target_sha: merge_request.target_branch_sha)
          end

          let_it_be(:merge_base_pipeline) do
            create(
              :ee_ci_pipeline,
              :success,
              :with_cyclonedx_report,
              project: project,
              ref: merge_request.target_branch,
              sha: merge_request.target_branch_sha)
          end

          it 'uses the merge base pipeline for comparison' do
            expect(::Gitlab::LicenseScanning).to receive(:scanner_for_pipeline)
              .with(project, merge_base_pipeline).and_return(sbom_scanner).ordered

            service.execute
          end

          describe 'policy bot comment' do
            before do
              allow(::Gitlab::LicenseScanning).to receive(:scanner_for_pipeline)
                                                    .with(project, merge_base_pipeline).and_return(sbom_scanner)
            end

            it_behaves_like 'triggers policy bot comment', :license_scanning, true, requires_approval: true
          end
        end

        context 'when the approval rules had approvals previously removed and rules are violated' do
          let_it_be(:approval_project_rule) do
            create(:approval_project_rule, :license_scanning, project: project, approvals_required: 2)
          end

          let!(:license_finding_rule) do
            create(:report_approver_rule, :license_scanning, merge_request: merge_request,
              approval_project_rule: approval_project_rule, approvals_required: 0,
              scan_result_policy_read: scan_result_policy_read)
          end

          it 'resets the required approvals' do
            expect { execute }.to change { license_finding_rule.reload.approvals_required }.to(2)
          end
        end
      end

      describe 'possible combinations' do
        using RSpec::Parameterized::TableSyntax

        where(:target_branch, :pipeline_branch, :states, :policy_license, :policy_state, :violated_license, :result) do
          ref(:case1) | ref(:case2) | ['newly_detected'] | ['GPL v3', 'GNU 3'] | :denied | 'GNU 3' | true
          ref(:case1) | ref(:case2) | ['newly_detected'] | [nil, 'GNU 3'] | :denied | 'GNU 3' | true
          ref(:case2) | ref(:case3) | ['newly_detected'] | ['GPL v3', 'GNU 3'] | :denied | 'GNU 3' | false
          ref(:case2) | ref(:case3) | ['newly_detected'] | [nil, 'GNU 3'] | :denied | 'GNU 3' | false
          ref(:case3) | ref(:case4) | ['newly_detected'] | ['GPL v3', 'GNU 3'] | :denied | 'GNU 3' | true
          ref(:case3) | ref(:case4) | ['newly_detected'] | [nil, 'GNU 3'] | :denied | 'GNU 3' | true
          ref(:case4) | ref(:case5) | ['newly_detected'] | ['GPL v3', 'GNU 3'] | :denied | 'GNU 3' | false
          ref(:case4) | ref(:case5) | ['newly_detected'] | [nil, 'GNU 3'] | :denied | 'GNU 3' | false
          ref(:case1) | ref(:case2) | ['detected'] | ['GPL v3', 'GNU 3'] | :denied | 'GNU 3' | false
          ref(:case1) | ref(:case2) | ['detected'] | [nil, 'GNU 3'] | :denied | 'GNU 3' | false
          ref(:case2) | ref(:case3) | ['detected'] | ['GPL v3', 'GNU 3'] | :denied | 'GNU 3' | true
          ref(:case2) | ref(:case3) | ['detected'] | [nil, 'GNU 3'] | :denied | 'GNU 3' | true
          ref(:case3) | ref(:case4) | ['detected'] | ['GPL v3', 'GNU 3'] | :denied | 'GNU 3' | true
          ref(:case3) | ref(:case4) | ['detected'] | [nil, 'GNU 3'] | :denied | 'GNU 3' | true
          ref(:case4) | ref(:case5) | ['detected'] | ['GPL v3', 'GNU 3'] | :denied | 'GNU 3' | true
          ref(:case4) | ref(:case5) | ['detected'] | [nil, 'GNU 3'] | :denied | 'GNU 3' | true

          ref(:case1) | ref(:case2) | ['newly_detected'] | ['MIT', 'MIT License'] | :allowed | 'GNU 3' | true
          ref(:case1) | ref(:case2) | ['newly_detected'] | [nil, 'MIT License'] | :allowed | 'GNU 3' | true
          ref(:case2) | ref(:case3) | ['newly_detected'] | ['MIT', 'MIT License'] | :allowed | nil | false
          ref(:case3) | ref(:case4) | ['newly_detected'] | ['MIT', 'MIT License'] | :allowed | 'GNU 3' | true
          ref(:case3) | ref(:case4) | ['newly_detected'] | [nil, 'MIT License'] | :allowed | 'GNU 3' | true
          ref(:case4) | ref(:case5) | ['newly_detected'] | ['MIT', 'MIT License'] | :allowed | 'Apache License 2' | true
          ref(:case4) | ref(:case5) | ['newly_detected'] | [nil, 'MIT License'] | :allowed | 'Apache License 2' | true
          ref(:case1) | ref(:case2) | ['detected'] | ['MIT', 'MIT License'] | :allowed | nil | false
          ref(:case1) | ref(:case2) | ['detected'] | [nil, 'MIT License'] | :allowed | nil | false
          ref(:case2) | ref(:case3) | ['detected'] | ['MIT', 'MIT License'] | :allowed | 'GNU 3' | true
          ref(:case2) | ref(:case3) | ['detected'] | [nil, 'MIT License'] | :allowed | 'GNU 3' | true
          ref(:case3) | ref(:case4) | ['detected'] | ['MIT', 'MIT License'] | :allowed | 'GNU 3' | true
          ref(:case3) | ref(:case4) | ['detected'] | [nil, 'MIT License'] | :allowed | 'GNU 3' | true
          ref(:case4) | ref(:case5) | ['detected'] | ['MIT', 'MIT License'] | :allowed | 'GNU 3' | true
          ref(:case4) | ref(:case5) | ['detected'] | [nil, 'MIT License'] | :allowed | 'GNU 3' | true

          # TODO: These cases fail. Related to https://gitlab.com/gitlab-org/gitlab/-/issues/438584
          # When spdx_identifier is used in policy instead of name, match_on_inclusion_license is evaluated incorrectly
          # ref(:case2) | ref(:case3) | ['newly_detected'] | [nil, 'MIT'] | :allowed | nil | false
          # ref(:case2) | ref(:case2) | ['detected'] | [nil, 'GPL v3'] | :allowed | nil | false
        end

        with_them do
          let(:match_on_inclusion_license) { policy_state == :denied }
          let(:target_branch_report) { create(:ci_reports_license_scanning_report) }
          let(:pipeline_report) { create(:ci_reports_license_scanning_report) }
          let(:license_states) { states }
          let(:license) { create(:software_license, spdx_identifier: policy_license[0], name: policy_license[1]) }

          before do
            target_branch.each do |ld|
              target_branch_report.add_license(id: ld[0], name: ld[1]).add_dependency(name: ld[2])
            end

            pipeline_branch.each do |ld|
              pipeline_report.add_license(id: ld[0], name: ld[1]).add_dependency(name: ld[2])
            end

            create(:software_license_policy, policy_state,
              project: project,
              software_license: license,
              scan_result_policy_read: scan_result_policy_read
            )

            allow(service).to receive(:report).and_return(pipeline_report)
            allow(service).to receive(:target_branch_report).and_return(target_branch_report)
          end

          it 'syncs approvals_required' do
            if result
              expect { execute }.not_to change { license_finding_rule.reload.approvals_required }
            else
              expect { execute }.to change { license_finding_rule.reload.approvals_required }.from(1).to(0)
            end
          end

          it 'logs only violated rules' do
            if result
              expect(Gitlab::AppJsonLogger).to receive(:info).with(hash_including(message: 'Updating MR approval rule'))
            else
              expect(Gitlab::AppJsonLogger).not_to receive(:info)
            end

            execute
          end

          describe 'violation data' do
            it 'persists violation data' do
              if result
                expect { execute }.to change { scan_result_policy_read.violations.count }.by(1)
                expect(scan_result_policy_read.violations.last.violation_data)
                  .to eq({ 'violations' => { 'licenses' => [violated_license] } })
              else
                expect { execute }.not_to change { scan_result_policy_read.violations.count }
              end
            end

            context 'when feature flag "save_policy_violation_data" is disabled' do
              before do
                stub_feature_flags(save_policy_violation_data: false)
              end

              it 'adds violations without data' do
                if result
                  expect { execute }.to change { scan_result_policy_read.violations.count }.by(1)
                  expect(scan_result_policy_read.violations.last.violation_data).to be_nil
                else
                  expect { execute }.not_to change { scan_result_policy_read.violations.count }
                end
              end
            end
          end
        end
      end
    end
  end
end
