# frozen_string_literal: true

require 'spec_helper'
require_relative './shared'

RSpec.describe 'Query.workspaces(ids: [RemoteDevelopmentWorkspaceID!])', feature_category: :remote_development do
  let_it_be(:workspace) { create(:workspace) }
  let_it_be(:authorized_user) { workspace.user }

  # create workspace with different ID but still owned by user, to ensure it is not returned by the query
  let_it_be(:non_matching_workspace) { create(:workspace, user: authorized_user) }

  let(:ids) { [workspace.to_global_id.to_s] }
  let(:args) { { ids: ids } }

  it_behaves_like 'a fully working Query.workspaces query'
end
