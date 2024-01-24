# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting list of branch rules for a project', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:current_user) { create(:user, maintainer_projects: [project]) }

  let(:branch_rules_data) { graphql_data_at('project', 'branchRules', 'nodes') }
  let(:variables) { { path: project.full_path } }
  let(:fields) { all_graphql_fields_for('BranchRule') }
  let(:query) do
    <<~GQL
    query($path: ID!, $n: Int, $cursor: String) {
      project(fullPath: $path) {
        branchRules(first: $n, after: $cursor) {
          nodes {
            #{fields}
          }
        }
      }
    }
    GQL
  end

  context 'when the user does have read_protected_branch abilities' do
    before do
      project.add_maintainer(current_user)
    end

    describe 'queries' do
      include_context 'when user tracking is disabled'

      let(:query) do
        <<~GQL
        query($path: ID!) {
          project(fullPath: $path) {
            branchRules {
              nodes {
                matchingBranchesCount
              }
            }
          }
        }
        GQL
      end

      before do
        create(:protected_branch, project: project)
      end

      it 'avoids N+1 queries', :use_sql_query_cache, :aggregate_failures do
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          post_graphql(query, current_user: current_user, variables: variables)
        end

        # Verify the response includes the field
        expect_n_matching_branches_count_fields(1)

        create(:protected_branch, project: project)
        create(:protected_branch, name: '*', project: project)

        expect do
          post_graphql(query, current_user: current_user, variables: variables)
        end.not_to exceed_all_query_limit(control)

        expect_n_matching_branches_count_fields(3)
      end

      def expect_n_matching_branches_count_fields(count)
        branch_rule_nodes = graphql_data_at('project', 'branchRules', 'nodes')
        expect(branch_rule_nodes.count).to eq(count)
        branch_rule_nodes.each do |node|
          expect(node['matchingBranchesCount']).to be_present
        end
      end
    end

    describe 'response' do
      let_it_be(:branch_name_a) { TestEnv::BRANCH_SHA.each_key.first }
      let_it_be(:branch_name_b) { 'diff-*' }
      let_it_be(:protected_branch_a) do
        create(:protected_branch, project: project, name: branch_name_a)
      end

      let_it_be(:protected_branch_b) do
        create(:protected_branch, project: project, name: branch_name_b)
      end

      let_it_be(:all_branches_external_status_check) do
        create(:external_status_check, project: project)
      end

      let_it_be(:all_branches_approval_rule) do
        create(:approval_project_rule, project: project)
      end

      let_it_be(:all_protected_branches_approval_rule) do
        create(:approval_project_rule, project: project, applies_to_all_protected_branches: true)
      end

      let(:branch_rule_a) { Projects::BranchRule.new(project, protected_branch_a) }
      let(:branch_rule_b) { Projects::BranchRule.new(project, protected_branch_b) }
      let(:all_branches_rule) { Projects::AllBranchesRule.new(project) }
      let(:all_protected_branches_rule) { Projects::AllProtectedBranchesRule.new(project) }
      # branchRules are returned in alphabetical order
      let(:all_branches_rule_data) { branch_rules_data.first }
      let(:all_protected_branches_rule_data) { branch_rules_data.second }
      let(:branch_rule_b_data) { branch_rules_data.third }
      let(:branch_rule_a_data) { branch_rules_data.fourth }

      before do
        post_graphql(query, current_user: current_user, variables: variables)
      end

      it_behaves_like 'a working graphql query'

      it 'includes all fields', :use_sql_query_cache, :aggregate_failures do
        expect(all_branches_rule_data).to include(
          'name' => all_branches_rule.name,
          'isDefault' => all_branches_rule.default_branch?,
          'isProtected' => all_branches_rule.protected?,
          'matchingBranchesCount' => all_branches_rule.matching_branches_count,
          'branchProtection' => all_branches_rule.branch_protection,
          'createdAt' => all_branches_rule.created_at.iso8601,
          'updatedAt' => all_branches_rule.updated_at.iso8601,
          'approvalRules' => be_kind_of(Hash),
          'externalStatusChecks' => be_kind_of(Hash)
        )
        approval_rules_data = all_branches_rule_data['approvalRules']['nodes']
        expect(approval_rules_data).to eq([{
          'id' => all_branches_approval_rule.to_global_id.to_s,
          'name' => all_branches_approval_rule.name,
          'type' => 'REGULAR',
          'approvalsRequired' => 0
        }])
        external_checks_data = all_branches_rule_data['externalStatusChecks']['nodes']
        expect(external_checks_data).to eq([{
          'id' => all_branches_external_status_check.to_global_id.to_s,
          'name' => all_branches_external_status_check.name,
          'externalUrl' => all_branches_external_status_check.external_url
        }])
        expect(all_protected_branches_rule_data).to include(
          'name' => all_protected_branches_rule.name,
          'isDefault' => all_protected_branches_rule.default_branch?,
          'isProtected' => all_protected_branches_rule.protected?,
          'matchingBranchesCount' => all_protected_branches_rule.matching_branches_count,
          'branchProtection' => all_protected_branches_rule.branch_protection,
          'createdAt' => all_protected_branches_rule.created_at.iso8601,
          'updatedAt' => all_protected_branches_rule.updated_at.iso8601,
          'approvalRules' => be_kind_of(Hash),
          'externalStatusChecks' => be_kind_of(Hash)
        )
        approval_rules_data = all_protected_branches_rule_data['approvalRules']['nodes']
        expect(approval_rules_data).to eq([{
          'id' => all_protected_branches_approval_rule.to_global_id.to_s,
          'name' => all_protected_branches_approval_rule.name,
          'type' => 'REGULAR',
          'approvalsRequired' => 0
        }])

        expect(branch_rule_a_data).to include(
          'name' => branch_rule_a.name,
          'isDefault' => branch_rule_a.default_branch?,
          'isProtected' => branch_rule_a.protected?,
          'matchingBranchesCount' => branch_rule_a.matching_branches_count,
          'branchProtection' => {
            "allowForcePush" => false,
            "codeOwnerApprovalRequired" => false
          },
          'createdAt' => branch_rule_a.created_at.iso8601,
          'updatedAt' => branch_rule_a.updated_at.iso8601,
          'approvalRules' => be_kind_of(Hash),
          'externalStatusChecks' => be_kind_of(Hash)
        )

        expect(branch_rule_b_data).to include(
          'name' => branch_rule_b.name,
          'isDefault' => branch_rule_b.default_branch?,
          'isProtected' => branch_rule_b.protected?,
          'matchingBranchesCount' => branch_rule_b.matching_branches_count,
          'branchProtection' => {
            "allowForcePush" => false,
            "codeOwnerApprovalRequired" => false
          },
          'createdAt' => branch_rule_a.created_at.iso8601,
          'updatedAt' => branch_rule_a.updated_at.iso8601,
          'approvalRules' => be_kind_of(Hash),
          'externalStatusChecks' => be_kind_of(Hash)
        )
      end
    end
  end
end
