# frozen_string_literal: true

require_relative '../shared'

RSpec.shared_examples 'a fully working Query.workspaces query' do
  include GraphqlHelpers

  include_context "with authorized user as developer on workspace's project"

  let(:fields) do
    <<~QUERY
      nodes {
        #{all_graphql_fields_for('workspaces'.classify, max_depth: 1)}
      }
    QUERY
  end

  let(:query) { graphql_query_for('workspaces', args, fields) }

  subject { graphql_data.dig('workspaces', 'nodes') }

  it_behaves_like 'multiple workspaces query'
end
