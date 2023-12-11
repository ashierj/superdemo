# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "User sees policies list", :js, feature_category: :security_policy_management do
  let_it_be(:owner) { create(:user) }
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, namespace: owner.namespace) }
  let_it_be(:policy_management_project) { create(:project, :repository, namespace: owner.namespace) }
  let_it_be(:policy_configuration) do
    create(
      :security_orchestration_policy_configuration,
      :namespace,
      security_policy_management_project: policy_management_project,
      namespace: group
    )
  end

  let_it_be(:project_scan_execution_policy_pipeline) do
    build(:scan_execution_policy, name: "Enforce SAST everyday for every project")
  end

  let_it_be(:policy_yaml) do
    Gitlab::Config::Loader::Yaml.new(fixture_file('security_orchestration.yml', dir: 'ee')).load!
  end

  before_all do
    group.add_owner(user)
    policy_management_project.add_owner(user)
  end

  before do
    allow_next_found_instance_of(Security::OrchestrationPolicyConfiguration) do |policy|
      allow(policy).to receive(:policy_configuration_valid?).and_return(true)
      allow(policy).to receive(:policy_hash).and_return(policy_yaml)
      allow(policy).to receive(:policy_last_updated_at).and_return(Time.current)
    end
    sign_in(user)
    stub_licensed_features(security_orchestration_policies: true)
  end

  it "shows the policies list with policies" do
    visit(group_security_policies_path(group))

    # Scan Execution Policy from ee/spec/fixtures/security_orchestration.yml
    expect(page).to have_content 'Run DAST in every pipeline'
    # Scan Result Policy from ee/spec/fixtures/security_orchestration.yml
    expect(page).to have_content 'critical vulnerability CS approvals'
  end
end
