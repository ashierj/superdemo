# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::UpdateViolationsService, '#execute', feature_category: :security_policy_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let_it_be(:policy_a) { create(:scan_result_policy_read, project: project) }
  let_it_be(:policy_b) { create(:scan_result_policy_read, project: project) }
  let_it_be(:rule_a) do
    create(:approval_merge_request_rule, merge_request: merge_request, scan_result_policy_id: policy_a.id)
  end

  let_it_be(:rule_b) do
    create(:approval_merge_request_rule, merge_request: merge_request, scan_result_policy_id: policy_b.id)
  end

  let(:violated_policies) { merge_request.approval_rules.with_policy_violation }

  subject(:service) { described_class.new(merge_request) }

  describe 'attributes' do
    subject(:attrs) { project.scan_result_policy_violations.last.attributes }

    before do
      service.add([rule_b])
      service.execute
    end

    specify do
      is_expected.to include(
        "scan_result_policy_id" => kind_of(Numeric),
        "merge_request_id" => kind_of(Numeric),
        "project_id" => kind_of(Numeric))
    end
  end

  context 'without pre-existing violations' do
    it 'creates violations' do
      service.add([rule_b])
      service.execute

      expect(violated_policies).to contain_exactly(rule_b)
    end
  end

  context 'with pre-existing violations' do
    before do
      service.add([rule_a])
      service.execute
    end

    it 'clears existing violations' do
      service.add([rule_b])
      service.execute

      expect(violated_policies).to contain_exactly(rule_b)
    end

    context 'with identical state' do
      it 'does not clear violations' do
        service.add([rule_a])
        service.execute

        expect(violated_policies).to contain_exactly(rule_a)
      end
    end
  end

  context 'without violations' do
    it 'clears all violations' do
      service.execute

      expect(violated_policies).to be_empty
    end
  end
end
