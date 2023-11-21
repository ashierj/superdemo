# frozen_string_literal: true

require 'spec_helper'
require_relative './shared'

RSpec.describe 'Query.workspaces(include_actual_states: [GraphQL::Types::String])', feature_category: :remote_development do
  let_it_be(:matching_state) { ::RemoteDevelopment::Workspaces::States::STOPPED }
  let_it_be(:non_matching_state) { ::RemoteDevelopment::Workspaces::States::RUNNING }
  let_it_be(:workspace) { create(:workspace, actual_state: matching_state) }
  let_it_be(:authorized_user) { workspace.user }

  # create workspace with non-matching actual state but still owned by current user,
  # to ensure it is not returned by the query
  # non_matching_workspace
  let_it_be(:non_matching_workspace) { create(:workspace, actual_state: non_matching_state, user: workspace.user) }

  let(:ids) { [workspace.to_global_id.to_s] }
  let(:args) { { include_actual_states: [matching_state] } }

  it_behaves_like 'a fully working Query.workspaces query'
end
