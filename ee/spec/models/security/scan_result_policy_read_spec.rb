# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ScanResultPolicyRead, feature_category: :security_policy_management do
  describe 'associations' do
    it { is_expected.to belong_to(:security_orchestration_policy_configuration) }
  end

  describe 'validations' do
    let_it_be(:scan_result_policy_read) { create(:scan_result_policy_read) }

    subject { scan_result_policy_read }

    it { is_expected.to validate_inclusion_of(:match_on_inclusion).in_array([true, false]) }

    it { is_expected.not_to allow_value(nil).for(:role_approvers) }
    it { is_expected.to(validate_inclusion_of(:role_approvers).in_array(Gitlab::Access.values)) }

    it { is_expected.not_to allow_value(-1).for(:age_value) }
    it { is_expected.to allow_value(0, 1).for(:age_value) }
    it { is_expected.to allow_value(nil).for(:age_value) }

    it { is_expected.not_to allow_value("string").for(:vulnerability_attributes) }
    it { is_expected.to allow_value({}).for(:vulnerability_attributes) }

    it do
      is_expected.to allow_value({ false_positive: true, fix_available: false }).for(:vulnerability_attributes)
    end

    it { is_expected.not_to allow_value("string").for(:project_approval_settings) }
    it { is_expected.to allow_value({}).for(:project_approval_settings) }

    it do
      is_expected.to allow_value(
        { prevent_approval_by_author: true, prevent_approval_by_commit_author: false,
          remove_approvals_with_new_commit: true, require_password_to_approve: false,
          block_branch_modification: true, block_group_branch_modification: true }
      ).for(:project_approval_settings)
    end

    it do
      is_expected.to allow_value(
        { block_group_branch_modification: { enabled: true, exceptions: %w[foobar] } }
      ).for(:project_approval_settings)
    end

    it do
      is_expected.to(
        validate_uniqueness_of(:rule_idx)
          .scoped_to(%i[security_orchestration_policy_configuration_id project_id orchestration_policy_idx]))
    end

    it { is_expected.to validate_numericality_of(:rule_idx).is_greater_than_or_equal_to(0).only_integer }
  end

  describe 'enums' do
    let(:age_operator_values) { { greater_than: 0, less_than: 1 } }
    let(:age_interval_values) { { day: 0, week: 1, month: 2, year: 3 } }

    it { is_expected.to define_enum_for(:age_operator).with_values(**age_operator_values) }
    it { is_expected.to define_enum_for(:age_interval).with_values(**age_interval_values) }
  end

  describe 'scopes' do
    describe '.blocking_branch_modification' do
      let_it_be(:non_blocking_read) { create(:scan_result_policy_read) }
      let_it_be(:blocking_read) do
        create(:scan_result_policy_read, project_approval_settings: { block_branch_modification: true })
      end

      it 'returns blocking reads' do
        expect(described_class.blocking_branch_modification).to contain_exactly(blocking_read)
      end
    end
  end

  describe '#newly_detected?' do
    subject { scan_result_policy_read.newly_detected? }

    context 'when license_states contains newly_detected' do
      let_it_be(:scan_result_policy_read) { create(:scan_result_policy_read, license_states: ['newly_detected']) }

      it { is_expected.to be_truthy }
    end

    context 'when license_states does not contain newly_detected' do
      let_it_be(:scan_result_policy_read) { create(:scan_result_policy_read, license_states: ['detected']) }

      it { is_expected.to be_falsey }
    end
  end

  describe '.for_project' do
    let_it_be(:project) { create(:project) }
    let_it_be(:scan_result_policy_read_1) { create(:scan_result_policy_read, project: project) }
    let_it_be(:scan_result_policy_read_2) { create(:scan_result_policy_read, project: project) }
    let_it_be(:scan_result_policy_read_3) { create(:scan_result_policy_read) }

    subject { described_class.for_project(project) }

    it 'returns records for given projects' do
      is_expected.to contain_exactly(scan_result_policy_read_1, scan_result_policy_read_2)
    end
  end

  describe '#vulnerability_age' do
    let_it_be(:scan_result_policy_read) do
      create(:scan_result_policy_read, age_operator: 'less_than', age_interval: 'day', age_value: 1)
    end

    subject { scan_result_policy_read.vulnerability_age }

    context 'when vulnerability age attributes are present' do
      it { is_expected.to eq({ operator: :less_than, interval: :day, value: 1 }) }
    end

    context 'when vulnerability age attributes are not present' do
      let_it_be(:scan_result_policy_read) do
        create(:scan_result_policy_read)
      end

      it { is_expected.to eq({}) }
    end
  end
end
