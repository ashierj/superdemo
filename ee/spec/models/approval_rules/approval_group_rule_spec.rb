# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApprovalRules::ApprovalGroupRule, feature_category: :source_code_management do
  let(:group_approval_rule) { build(:approval_group_rule) }

  describe 'validations' do
    it { expect(group_approval_rule).to validate_presence_of(:name) }
    it { expect(group_approval_rule).to validate_uniqueness_of(:name).scoped_to([:group_id, :rule_type]) }
    it { expect(group_approval_rule).to validate_numericality_of(:approvals_required).is_less_than_or_equal_to(100) }
    it { expect(group_approval_rule).to validate_numericality_of(:approvals_required).is_greater_than_or_equal_to(0) }

    context 'for applies_to_all_protected_branches' do
      it 'is default true' do
        expect(group_approval_rule.applies_to_all_protected_branches).to be_truthy
      end

      it 'cannot be false' do
        expect do
          group_approval_rule.update!(applies_to_all_protected_branches: false)
        end.to raise_error(ActiveRecord::RecordInvalid,
          'Validation failed: Applies to all protected branches must be enabled.')
      end
    end
  end

  describe 'associations' do
    it { expect(group_approval_rule).to belong_to(:group).inverse_of(:approval_rules) }
    it { expect(group_approval_rule).to belong_to(:security_orchestration_policy_configuration) }
    it { expect(group_approval_rule).to belong_to(:scan_result_policy_read) }
    it { expect(group_approval_rule).to have_and_belong_to_many(:users) }
    it { expect(group_approval_rule).to have_and_belong_to_many(:groups) }
    it { expect(group_approval_rule).to have_and_belong_to_many(:protected_branches) }
  end

  describe 'any_approver rules' do
    let_it_be(:group) { create(:group) }

    let(:rule) { build(:approval_group_rule, group: group, rule_type: :any_approver) }

    it 'allows to create only one any_approver rule', :aggregate_failures do
      create(:approval_group_rule, group: group, rule_type: :any_approver)

      expect(rule).not_to be_valid
      expect(rule.errors.messages).to eq(rule_type: ['any-approver for the group already exists'])
    end
  end
end
