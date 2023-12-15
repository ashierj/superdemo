# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Policy editor", :js, feature_category: :security_policy_management do
  include ListboxHelpers

  let_it_be(:owner) { create(:user) }
  let_it_be(:project) { create(:project, :repository, namespace: owner.namespace) }
  let_it_be(:protected_branch) { create(:protected_branch, name: 'spooky-stuff', project: project) }
  let_it_be(:policy_management_project) { create(:project, :repository, namespace: owner.namespace) }
  let_it_be(:policy_configuration) do
    create(
      :security_orchestration_policy_configuration,
      security_policy_management_project: policy_management_project,
      project: project
    )
  end

  it_behaves_like 'policy editor' do
    let(:path_to_policy_editor) { new_project_security_policy_path(project) }
  end
end
