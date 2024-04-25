# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group Workspaces Settings', :js, feature_category: :remote_development do
  include WaitForRequests

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before_all do
    group.add_developer(user)
  end

  before do
    stub_licensed_features(remote_development: true)
    stub_feature_flags(remote_development_namespace_agent_authorization: true)

    sign_in(user)
    visit group_settings_workspaces_path(group)
    wait_for_requests
  end

  it 'renders workspaces settings page' do
    expect(page).to have_content 'Workspaces Settings'
  end
end
