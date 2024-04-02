# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ScanResultPolicies::PolicyViolationDetails, feature_category: :security_policy_management do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project, :repository) }
  let_it_be_with_reload(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:security_orchestration_policy_configuration) do
    create(:security_orchestration_policy_configuration, project: project)
  end

  let_it_be(:policy1) do
    create(:scan_result_policy_read, project: project,
      security_orchestration_policy_configuration: security_orchestration_policy_configuration)
  end

  let_it_be(:policy2) do
    create(:scan_result_policy_read, project: project,
      security_orchestration_policy_configuration: security_orchestration_policy_configuration)
  end

  let_it_be(:policy3) do
    create(:scan_result_policy_read, project: project,
      security_orchestration_policy_configuration: security_orchestration_policy_configuration)
  end

  let_it_be(:scan_finding_rule_policy1) do
    create(:report_approver_rule, :scan_finding, merge_request: merge_request,
      scan_result_policy_read: policy1, name: 'Policy 1')
  end

  let_it_be(:license_scanning_rule_policy2) do
    create(:report_approver_rule, :license_scanning, merge_request: merge_request,
      scan_result_policy_read: policy2, name: 'Policy 2')
  end

  let_it_be(:any_merge_request_rule_policy3) do
    create(:report_approver_rule, :any_merge_request, merge_request: merge_request,
      scan_result_policy_read: policy3, name: 'Policy 3')
  end

  let_it_be(:uuid) { SecureRandom.uuid }
  let_it_be(:uuid_previous) { SecureRandom.uuid }
  let_it_be(:scanner) { create(:vulnerabilities_scanner, project: project) }
  let_it_be(:pipeline) do
    create(:ee_ci_pipeline, :success, :with_dependency_scanning_report, project: project,
      ref: merge_request.source_branch, sha: merge_request.diff_head_sha,
      merge_requests_as_head_pipeline: [merge_request])
  end

  let_it_be(:ci_build) { pipeline.builds.first }

  let(:details) { described_class.new(merge_request) }

  def build_violation_details(policy, data)
    create(:scan_result_policy_violation, project: project, merge_request: merge_request,
      scan_result_policy_read: policy, violation_data: data)
  end

  describe '#violations' do
    subject(:violations) { details.violations }

    where(:policy, :name, :report_type, :data) do
      ref(:policy1) | 'Policy 1' | 'scan_finding' | { 'violations' => { 'scan_finding' => {} } }
      ref(:policy2) | 'Policy 2' | 'license_scanning' | { 'violations' => { 'license_scanning' => {} } }
      ref(:policy3) | 'Policy 3' | 'any_merge_request' | { 'violations' => { 'any_merge_request' => {} } }
    end

    with_them do
      before do
        create(:scan_result_policy_violation, project: project, merge_request: merge_request,
          scan_result_policy_read: policy, violation_data: data)
      end

      it 'has correct attributes', :aggregate_failures do
        expect(violations.size).to eq 1

        violation = violations.first
        expect(violation.name).to eq name
        expect(violation.report_type).to eq report_type
        expect(violation.data).to eq data
        expect(violation.scan_result_policy_id).to eq policy.id
      end
    end
  end

  describe 'scan finding violations' do
    before_all do
      pipeline_scan = create(:security_scan, :succeeded, build: ci_build, scan_type: 'dependency_scanning')
      create(:security_finding, :with_finding_data, scan: pipeline_scan, scanner: scanner, severity: 'high',
        uuid: uuid, location: { start_line: 3, file: '.env' })
      create(:vulnerabilities_finding, :with_secret_detection, project: project, scanner: scanner,
        uuid: uuid_previous, name: 'AWS API key')

      build_violation_details(policy1,
        context: { pipeline_ids: [pipeline.id] },
        violations: { scan_finding: { uuids: { newly_detected: [uuid], previously_existing: [uuid_previous] } } }
      )
      # Unrelated violation that is expected to be filtered out
      build_violation_details(policy3, violations: { any_merge_request: { commits: true } })
    end

    describe '#new_scan_finding_violations' do
      let(:violation) { new_scan_finding_violations.first }

      subject(:new_scan_finding_violations) { details.new_scan_finding_violations }

      context 'with additional unrelated violation' do
        before do
          build_violation_details(policy2,
            violations: { scan_finding: { uuids: { previously_existing: [uuid_previous] } } }
          )
        end

        it 'returns only related new scan finding violations', :aggregate_failures do
          expect(new_scan_finding_violations.size).to eq 1

          expect(violation.report_type).to eq 'dependency_scanning'
          expect(violation.name).to eq 'Test finding'
          expect(violation.severity).to eq 'high'
          expect(violation.path).to match(/^http.+\.env#L3$/)
          expect(violation.location).to match(file: '.env', start_line: 3)
        end
      end

      context 'when multiple policies containing the same uuid' do
        before do
          build_violation_details(policy2,
            context: { pipeline_ids: [pipeline.id] },
            violations: {
              scan_finding: { uuids: { newly_detected: [uuid] } }
            }
          )
        end

        it 'returns de-duplicated violations', :aggregate_failures do
          expect(new_scan_finding_violations.size).to eq 1

          expect(violation.report_type).to eq 'dependency_scanning'
          expect(violation.name).to eq 'Test finding'
          expect(violation.severity).to eq 'high'
          expect(violation.path).to match(/^http.+\.env#L3$/)
          expect(violation.location).to match(file: '.env', start_line: 3)
        end
      end
    end

    describe '#previous_scan_finding_violations' do
      let(:violation) { previous_scan_finding_violations.first }

      subject(:previous_scan_finding_violations) { details.previous_scan_finding_violations }

      context 'with additional unrelated violation' do
        before do
          build_violation_details(policy2,
            context: { pipeline_ids: [pipeline.id] },
            violations: { scan_finding: { uuids: { newly_detected: [uuid] } } }
          )
        end

        it 'returns only related previous scan finding violations', :aggregate_failures do
          expect(previous_scan_finding_violations.size).to eq 1

          expect(violation.report_type).to eq 'secret_detection'
          expect(violation.name).to eq 'AWS API key'
          expect(violation.severity).to eq 'critical'
          expect(violation.path).to match(/^http.+aws-key\.py#L5$/)
          expect(violation.location).to match(hash_including(file: 'aws-key.py', start_line: 5))
        end
      end

      context 'when multiple policies containing the same uuid' do
        before do
          build_violation_details(policy2,
            violations: {
              scan_finding: { uuids: { previously_existing: [uuid_previous] } }
            }
          )
        end

        it 'returns de-duplicated violations', :aggregate_failures do
          expect(previous_scan_finding_violations.size).to eq 1

          expect(violation.report_type).to eq 'secret_detection'
          expect(violation.name).to eq 'AWS API key'
          expect(violation.severity).to eq 'critical'
          expect(violation.path).to match(/^http.+aws-key\.py#L5$/)
          expect(violation.location).to match(hash_including(file: 'aws-key.py', start_line: 5))
        end
      end
    end
  end

  describe '#any_merge_request_violations' do
    subject(:violations) { details.any_merge_request_violations }

    before do
      build_violation_details(policy3, violations: { any_merge_request: { commits: commits } })
      # Unrelated violation that is expected to be filtered out
      build_violation_details(policy1,
        context: { pipeline_ids: [pipeline.id] },
        violations: { scan_finding: { uuids: { newly_detected: [uuid], previously_existing: [uuid_previous] } } }
      )
    end

    context 'when commits is boolean' do
      let(:commits) { true }

      it 'returns only any_merge_request violations', :aggregate_failures do
        expect(violations.size).to eq 1

        violation = violations.first
        expect(violation.name).to eq 'Policy 3'
        expect(violation.commits).to eq true
      end
    end

    context 'when commits is array' do
      let(:commits) { ['abcd1234'] }

      it 'returns only any_merge_request violations', :aggregate_failures do
        expect(violations.size).to eq 1

        violation = violations.first
        expect(violation.name).to eq 'Policy 3'
        expect(violation.commits).to match_array(['abcd1234'])
      end
    end
  end
end
