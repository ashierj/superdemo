# frozen_string_literal: true

require 'spec_helper'
require_relative '../shared'

RSpec.describe 'Query.workspace(id: RemoteDevelopmentWorkspaceID!)', feature_category: :remote_development do
  include GraphqlHelpers

  include_context "with authorized user as developer on workspace's project"

  RSpec.shared_examples 'single workspace query' do
    context 'when remote_development feature is licensed' do
      include_context 'in licensed environment'

      context 'when user is authorized' do
        include_context 'with authorized user'

        it_behaves_like 'query is a working graphql query'
        it_behaves_like 'query returns workspace'

        context 'when the user requests a workspace that they are not authorized for' do
          let_it_be(:other_workspace) { create(:workspace) }
          let(:id) { other_workspace.to_global_id.to_s }

          it_behaves_like 'query returns blank'
        end
      end

      context 'when user is not authorized' do
        include_context 'with unauthorized user as current user'

        it_behaves_like 'query is a working graphql query'
        it_behaves_like 'query returns blank'
      end
    end

    it_behaves_like 'query in unlicensed environment'
  end

  RSpec.shared_examples 'a fully working Query.workspace query' do
    let(:fields) do
      <<~QUERY
        #{all_graphql_fields_for('workspace'.classify, max_depth: 1)}
      QUERY
    end

    let(:query) { graphql_query_for('workspace', args, fields) }

    subject { graphql_data['workspace'] }

    it_behaves_like 'single workspace query'
  end

  # NOTE: Even though this single-workspace spec only has one scenario to test, we still use the same shared examples
  #       patterns as the other multi-workspace query specs, for consistency.

  let_it_be(:workspace) { create(:workspace) }
  let_it_be(:authorized_user) { workspace.user }
  let(:id) { workspace.to_global_id.to_s }
  let(:args) { { id: id } }

  it_behaves_like 'a fully working Query.workspace query'
end
