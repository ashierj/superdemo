# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::WorkspacesForUserFinder, feature_category: :remote_development do
  include ::RemoteDevelopment::Workspaces::States

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project_a) { create(:project, :public) }
  let_it_be(:project_b) { create(:project, :public) }
  let_it_be(:workspace_a) do
    create(:workspace, user: current_user, updated_at: 2.days.ago, project_id: project_a.id,
      actual_state: ::RemoteDevelopment::Workspaces::States::RUNNING
    )
  end

  let_it_be(:workspace_b) do
    create(:workspace, user: current_user, updated_at: 1.day.ago, project_id: project_b.id,
      actual_state: ::RemoteDevelopment::Workspaces::States::TERMINATED
    )
  end

  let_it_be(:other_users_workspace) { create(:workspace, user: create(:user), project_id: project_a.id) }

  subject(:found_workspaces) { described_class.new(user: current_user, params: params).execute }

  before do
    stub_licensed_features(remote_development: true)
  end

  context 'with blank params' do
    let(:params) { {} }

    it "returns current user's workspaces sorted by last updated time (most recent first)" do
      # The following line results in a dangerbot warning, but unfortunately there doesn't seem to be
      # an exact-order array matcher that doesn't result in a dangerbot warning.
      expect(found_workspaces).to eq([workspace_b, workspace_a])
    end
  end

  context 'with id in params' do
    let(:params) { { ids: [workspace_a.id] } }

    it "returns only current user's workspaces matching the specified IDs" do
      expect(found_workspaces).to contain_exactly(workspace_a)
      expect(found_workspaces).not_to include(other_users_workspace)
    end
  end

  context 'with project_ids in params' do
    let(:params) { { project_ids: [project_a.id] } }

    it "returns only current user's workspaces matching the specified project IDs" do
      expect(found_workspaces).to contain_exactly(workspace_a)
      expect(found_workspaces).not_to include(other_users_workspace)
    end
  end

  context 'with include_actual_states in params' do
    let(:params) { { include_actual_states: [::RemoteDevelopment::Workspaces::States::RUNNING] } }

    it "returns only current user's workspaces not matching the specified actual_states" do
      expect(found_workspaces).to contain_exactly(workspace_a)
      expect(found_workspaces).not_to include(other_users_workspace)
    end
  end

  context 'when user does not have access_workspaces_feature ability (anonymous user)' do
    let(:params) { {} }

    before do
      allow(current_user).to receive(:can?).with(:access_workspaces_feature).and_return(false)
    end

    it 'returns none' do
      expect(found_workspaces).to be_blank
    end
  end

  context 'without valid license' do
    let(:params) { {} }

    before do
      stub_licensed_features(remote_development: false)
    end

    it 'returns none' do
      expect(found_workspaces).to be_blank
    end
  end
end
