# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Policy editor", :js, feature_category: :security_policy_management do
  include ListboxHelpers

  let_it_be(:owner) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:policy_management_project) { create(:project, :repository, namespace: owner.namespace) }
  let_it_be(:policy_configuration) do
    create(
      :security_orchestration_policy_configuration,
      :namespace,
      security_policy_management_project: policy_management_project,
      namespace: group
    )
  end

  before_all do
    group.add_owner(owner)
  end

  it_behaves_like 'policy editor' do
    let(:path_to_policy_editor) { new_group_security_policy_path(group) }
  end
end
