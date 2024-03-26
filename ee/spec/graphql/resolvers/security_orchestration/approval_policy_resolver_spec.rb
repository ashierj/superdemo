# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::SecurityOrchestration::ApprovalPolicyResolver, feature_category: :security_policy_management do
  include GraphqlHelpers

  include_context 'orchestration policy context'

  let(:policy) { build(:approval_policy, name: 'Require security approvals') }
  let(:policy_yaml) { build(:orchestration_policy_yaml, approval_policy: [policy]) }
  let(:expected_resolved) do
    [
      {
        name: 'Require security approvals',
        description: 'This policy considers only container scanning and critical severities',
        edit_path: Gitlab::Routing.url_helpers.edit_project_security_policy_url(
          project, id: CGI.escape(policy[:name]), type: 'approval_policy'
        ),
        enabled: true,
        policy_scope: {
          compliance_frameworks: [],
          including_projects: [],
          excluding_projects: []
        },
        yaml: YAML.dump(policy.deep_stringify_keys),
        updated_at: policy_last_updated_at,
        user_approvers: [],
        group_approvers: [],
        all_group_approvers: [],
        role_approvers: [],
        source: {
          inherited: false,
          namespace: nil,
          project: project
        }
      }
    ]
  end

  before do
    stub_feature_flags(security_policies_breaking_changes: false)
  end

  subject(:resolve_scan_policies) { resolve(described_class, obj: project, ctx: { current_user: user }) }

  it_behaves_like 'as an orchestration policy'

  context 'when the feature flag security_policies_breaking_changes is enabled' do
    before do
      stub_feature_flags(security_policies_breaking_changes: true)
    end

    let(:expected_resolved) do
      [
        {
          name: 'Require security approvals',
          description: 'This policy considers only container scanning and critical severities',
          edit_path: Gitlab::Routing.url_helpers.edit_project_security_policy_url(
            project, id: CGI.escape(policy[:name]), type: 'approval_policy'
          ),
          enabled: true,
          policy_scope: {
            compliance_frameworks: [],
            including_projects: [],
            excluding_projects: []
          },
          yaml: YAML.dump(policy.deep_stringify_keys),
          updated_at: policy_last_updated_at,
          user_approvers: [],
          group_approvers: [],
          all_group_approvers: [],
          deprecated_properties: [],
          role_approvers: [],
          source: {
            inherited: false,
            namespace: nil,
            project: project
          }
        }
      ]
    end

    it_behaves_like 'as an orchestration policy'
  end
end
