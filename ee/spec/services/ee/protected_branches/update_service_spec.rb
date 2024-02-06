# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranches::UpdateService, feature_category: :compliance_management do
  let_it_be(:project) { create(:project, :repository) }
  let(:branch_name) { 'feature' }
  let(:protected_branch) { create(:protected_branch, name: branch_name, project: project) }
  let(:user) { project.first_owner }

  subject(:service) { described_class.new(project, user, params) }

  describe '#execute' do
    context 'with invalid params' do
      let(:params) do
        {
          name: branch_name,
          push_access_levels_attributes: [{ access_level: Gitlab::Access::MAINTAINER }]
        }
      end

      it "does not add a security audit event entry" do
        expect { service.execute(protected_branch) }.not_to change(::AuditEvent, :count)
      end
    end

    context 'with valid params' do
      let(:params) do
        {
          name: branch_name,
          merge_access_levels_attributes: [{ access_level: Gitlab::Access::DEVELOPER }],
          push_access_levels_attributes: [{ access_level: Gitlab::Access::DEVELOPER }]
        }
      end

      it 'adds security audit event entries' do
        expect { service.execute(protected_branch) }.to change(::AuditEvent, :count).by(2)
      end
    end
  end

  context 'with blocking scan result policy' do
    let(:params) { { name: branch_name.reverse } }

    let(:policy_configuration) do
      create(:security_orchestration_policy_configuration, project: project)
    end

    include_context 'with scan result policy blocking protected branches'

    before do
      create(:scan_result_policy_read, :blocking_protected_branches, project: project,
        security_orchestration_policy_configuration: policy_configuration)
    end

    it 'raises' do
      expect { service.execute(protected_branch) }.to raise_error(::Gitlab::Access::AccessDeniedError)
    end

    context 'with feature disabled' do
      before do
        stub_feature_flags(scan_result_policies_block_unprotecting_branches: false)
      end

      it 'renames' do
        expect { service.execute(protected_branch) }.to change { protected_branch.reload.name }.to(branch_name.reverse)
      end
    end
  end
end
