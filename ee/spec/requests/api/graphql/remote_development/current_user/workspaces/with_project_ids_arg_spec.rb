# frozen_string_literal: true

require 'spec_helper'
require_relative './shared'

RSpec.describe 'Query.workspaces(project_ids: [::Types::GlobalIDType[Project]!])', feature_category: :remote_development do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:workspace) { create(:workspace, project_id: project.id) }
  let_it_be(:authorized_user) { workspace.user }

  # create workspace with different project but still owned by current user, to ensure it is not returned by the query
  let_it_be(:non_matching_workspace) { create(:workspace, user: workspace.user) }

  let(:project_ids) { [project.to_global_id.to_s] }
  let(:args) { { project_ids: project_ids } }

  it_behaves_like 'a fully working Query.currentUser.workspaces query'
end
