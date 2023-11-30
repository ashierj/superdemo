# frozen_string_literal: true

require_relative '../../shared'

RSpec.shared_examples 'a fully working Query.currentUser.workspaces query' do
  include GraphqlHelpers

  include_context "with authorized user as developer on workspace's project"

  let(:fields) do
    <<~QUERY
      nodes {
        #{all_graphql_fields_for('workspaces'.classify, max_depth: 1)}
      }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'currentUser',
      query_graphql_field('workspaces', args, fields)
    )
  end

  subject { graphql_data.dig('currentUser', 'workspaces', 'nodes') }

  it_behaves_like 'multiple workspaces query'
end
