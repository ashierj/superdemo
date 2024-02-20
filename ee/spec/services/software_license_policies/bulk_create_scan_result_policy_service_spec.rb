# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SoftwareLicensePolicies::BulkCreateScanResultPolicyService, feature_category: :security_policy_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:scan_result_policy) { create(:scan_result_policy_read) }
  let(:params) do
    [
      { name: 'ExamplePL/2.1', approval_status: 'denied', scan_result_policy_read: scan_result_policy },
      { name: 'ExamplePL/2.2', approval_status: 'allowed', scan_result_policy_read: scan_result_policy },
      { name: 'MIT', approval_status: 'allowed', scan_result_policy_read: scan_result_policy }
    ]
  end

  subject(:execute_service) { described_class.new(project, params).execute }

  describe '#execute', :aggregate_failures do
    context 'when valid parameters are specified' do
      it 'creates missing software licenses' do
        expect { execute_service }.to change { SoftwareLicense.count }.by(3)
      end

      it 'creates one software license policy correctly',
        quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/442288' do
        result = execute_service
        created_policy = SoftwareLicensePolicy.find_by(result[:software_license_policy].first)

        expect(project.software_license_policies.count).to be(3)
        expect(result[:software_license_policy].count).to eq(3)
        expect(result[:status]).to be(:success)

        expect(created_policy.attributes.with_indifferent_access).to include(
          {
            classification: "denied",
            project_id: project.id,
            scan_result_policy_id: scan_result_policy.id
          }
        )
      end

      it 'inserts software licenses and license policies in batches' do
        stub_const("#{described_class.name}::BATCH_SIZE", 2)

        query_recorder = ActiveRecord::QueryRecorder.new { execute_service }

        license_queries = query_recorder.log.count { |q| q.include?('INSERT INTO "software_licenses"') }
        policy_queries = query_recorder.log.count { |q| q.include?('INSERT INTO "software_license_policies"') }

        expect(license_queries).to eq(2)
        expect(policy_queries).to eq(2)
      end

      context 'when name contains whitespaces' do
        let(:params) { [{ name: '  MIT   ', approval_status: 'allowed', scan_result_policy_read: scan_result_policy }] }

        it 'creates one software license policy with stripped name',
          quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/442288' do
          result = execute_service
          created_policy = SoftwareLicensePolicy.find_by(result[:software_license_policy].first)

          expect(project.software_license_policies.count).to be(1)
          expect(result[:status]).to be(:success)
          expect(created_policy.software_license.name).to eq('MIT')
        end
      end
    end

    context "when invalid input is provided" do
      let(:params) do
        [
          { name: 'ExamplePL/2.1', scan_result_policy_read: scan_result_policy },
          { name: 'ExamplePL/2.2', approval_status: 'allowed' }
        ]
      end

      it 'does not create invalid records' do
        expect { execute_service }.to change { project.software_license_policies.count }.by(0)
      end

      specify { expect(execute_service[:status]).to be(:success) }
    end
  end
end
