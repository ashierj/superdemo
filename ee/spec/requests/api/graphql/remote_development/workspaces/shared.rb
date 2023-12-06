# frozen_string_literal: true

require_relative '../shared'

RSpec.shared_context 'for a Query.workspaces query' do
  include GraphqlHelpers

  let_it_be(:authorized_user) { create(:admin) }

  # Only instance admins may use this query, all other users, even workspace owners, will get an empty result
  let_it_be(:workspace_owner) { workspace.user }
  let_it_be(:unauthorized_user) { workspace_owner }

  let(:fields) do
    <<~QUERY
      nodes {
        #{all_graphql_fields_for('workspaces'.classify, max_depth: 1)}
      }
    QUERY
  end

  let(:query) { graphql_query_for('workspaces', args, fields) }

  subject { graphql_data.dig('workspaces', 'nodes') }

  before do
    workspace.project.add_developer(workspace_owner)
  end
end
