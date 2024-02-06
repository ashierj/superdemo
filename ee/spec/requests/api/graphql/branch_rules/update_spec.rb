# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'BranchRuleUpdate', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }
  let!(:branch_rule) { create(:protected_branch, project: project) }
  let(:current_user) { user }
  let(:mutation) { graphql_mutation(:branch_rule_update, params) }

  let(:params) do
    {
      id: branch_rule.to_global_id,
      project_path: project.full_path,
      name: branch_rule.name.reverse
    }
  end

  subject(:post_mutation) { post_graphql_mutation(mutation, current_user: user) }

  before_all do
    project.add_maintainer(user)
  end

  context 'with blocking scan result policy' do
    let(:branch_name) { branch_rule.name }
    let(:policy_configuration) do
      create(:security_orchestration_policy_configuration, project: project)
    end

    include_context 'with scan result policy blocking protected branches'

    before do
      create(:scan_result_policy_read, :blocking_protected_branches, project: project,
        security_orchestration_policy_configuration: policy_configuration)
    end

    it_behaves_like 'a mutation that returns top-level errors',
      errors: ["Internal server error: Gitlab::Access::AccessDeniedError"]
  end
end
