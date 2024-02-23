# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BranchRules::UpdateService, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:name) { 'new_name' }
  let_it_be(:params) { { name: name } }

  describe '#execute' do
    subject(:execute) { described_class.new(branch_rule, user, params).execute }

    before do
      allow(Ability).to receive(:allowed?).and_return(true)
    end

    context 'when branch_rule is a Projects::AllBranchesRule' do
      let(:branch_rule) { Projects::AllBranchesRule.new(project) }

      it 'returns an error response' do
        response = execute
        expect(response).to be_error
        expect(response[:message]).to eq('All branch rules cannot be updated')
      end
    end

    context 'when branch_rule is a Projects::AllProtectedBranchesRule' do
      let(:branch_rule) { Projects::AllProtectedBranchesRule.new(project) }

      it 'returns an error response' do
        response = execute
        expect(response).to be_error
        expect(response[:message]).to eq('All protected branch rules cannot be updated')
      end
    end

    context 'when branch_rule is a ProtectedBranch' do
      let(:protected_branch) { create(:protected_branch) }
      let(:branch_rule) { Projects::BranchRule.new(project, protected_branch) }

      it 'returns a success response' do
        response = execute
        expect(response).to be_success
        expect(protected_branch.reload.name).to eq(name)
      end
    end
  end
end
