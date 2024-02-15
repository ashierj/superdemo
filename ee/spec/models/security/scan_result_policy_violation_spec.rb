# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ScanResultPolicyViolation, feature_category: :security_policy_management do
  let_it_be(:violation) { create(:scan_result_policy_violation) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:scan_result_policy_read) }
    it { is_expected.to belong_to(:merge_request) }
  end

  describe 'validations' do
    subject { violation }

    it { is_expected.to(validate_uniqueness_of(:scan_result_policy_id).scoped_to(%i[merge_request_id])) }

    describe 'violation_data' do
      it { is_expected.not_to allow_value('string').for(:violation_data) }
      it { is_expected.to allow_value({}).for(:violation_data) }

      it do
        is_expected.to allow_value(
          { violations: { uuids: { newly_detected: ['123'], previously_existing: ['456'] }, licenses: ['MIT'] },
            context: { pipeline_ids: [123], target_pipeline_ids: [456] } }
        ).for(:violation_data)
      end

      it do
        is_expected.to allow_value(
          { errors: [{ error: 'SCAN_REMOVED', missing_scans: ['sast'] }] }
        ).for(:violation_data)
      end

      it { is_expected.not_to allow_value({ errors: [{}] }).for(:violation_data) }
    end
  end

  describe '.for_approval_rules' do
    subject { described_class.for_approval_rules(approval_rules) }

    context 'when approval rules are empty' do
      let(:approval_rules) { [] }

      it { is_expected.to be_empty }
    end

    context 'when approval rules are present' do
      let_it_be(:project) { create(:project) }
      let_it_be(:scan_result_policy_read_1) { create(:scan_result_policy_read, project: project) }
      let_it_be(:scan_result_policy_read_2) { create(:scan_result_policy_read, project: project) }
      let_it_be(:scan_result_policy_read_3) { create(:scan_result_policy_read, project: project) }
      let_it_be(:other_violations) do
        [
          create(:scan_result_policy_violation, project: project, scan_result_policy_read: scan_result_policy_read_2),
          create(:scan_result_policy_violation, project: project, scan_result_policy_read: scan_result_policy_read_3)
        ]
      end

      let(:approval_rules) do
        create_list(:report_approver_rule, 1, :scan_finding, scan_result_policy_read: scan_result_policy_read_1)
      end

      let_it_be(:scan_finding_violation) do
        create(:scan_result_policy_violation, project: project, scan_result_policy_read: scan_result_policy_read_1)
      end

      it { is_expected.to contain_exactly scan_finding_violation }
    end
  end
end
