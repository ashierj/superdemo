# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::UpdateViolationsService, '#execute', feature_category: :security_policy_management do
  let(:service) { described_class.new(merge_request) }
  let_it_be(:project) { create(:project) }
  let_it_be(:merge_request, reload: true) do
    create(:merge_request, source_project: project, target_project: project)
  end

  let_it_be(:policy_a) { create(:scan_result_policy_read, project: project) }
  let_it_be(:policy_b) { create(:scan_result_policy_read, project: project) }
  let(:violated_policies) { violations.map(&:scan_result_policy_read) }

  subject(:violations) { merge_request.scan_result_policy_violations }

  describe 'attributes' do
    subject(:attrs) { project.scan_result_policy_violations.last.attributes }

    before do
      service.add([policy_b.id], [])
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
    before do
      service.add([policy_b.id], [])
    end

    it 'creates violations' do
      service.execute

      expect(violated_policies).to contain_exactly(policy_b)
    end

    it 'can persist violation data' do
      service.set_violation_data(policy_b.id, { violations: { uuid: { newly_detected: [123] } } })
      service.execute

      expect(violations.last.violation_data).to eq({ "violations" => { "uuid" => { "newly_detected" => [123] } } })
    end
  end

  context 'with pre-existing violations' do
    before do
      service.add([policy_a.id], [])
      service.set_violation_data(policy_a.id, { violations: { uuid: { newly_detected: [123] } } })
      service.execute
    end

    it 'clears existing violations' do
      service.add([policy_b.id], [policy_a.id])
      service.execute

      expect(violated_policies).to contain_exactly(policy_b)
    end

    it 'updates existing violation data' do
      service.add([policy_a.id], [])
      service.set_violation_data(policy_a.id, { errors: [{ error: 'SCAN_REMOVED', missing_scans: ['sast'] }] })

      expect { service.execute }
        .to change { violations.last.violation_data }.to(
          { "errors" => [{ "error" => "SCAN_REMOVED", "missing_scans" => ["sast"] }] }
        )
    end

    context 'with identical state' do
      it 'does not clear violations' do
        service.add([policy_a.id], [])

        expect { service.execute }.not_to change { violations.last.violation_data }
        expect(violated_policies).to contain_exactly(policy_a)
      end
    end
  end

  context 'with unrelated existing violation' do
    let_it_be(:unrelated_violation) do
      create(:scan_result_policy_violation, scan_result_policy_read: policy_a, merge_request: merge_request)
    end

    before do
      service.add([], [policy_b.id])
    end

    it 'removes only violations provided in unviolated ids' do
      service.execute

      expect(violations).to contain_exactly(unrelated_violation)
    end
  end

  context 'without violations' do
    it 'clears all violations' do
      service.execute

      expect(violations).to be_empty
    end
  end
end
