# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "GraphQL Pipeline Subscriptions", '(JavaScript fixtures)', type: :request, feature_category: :pipeline_composition do
  include ApiHelpers
  include GraphqlHelpers
  include JavaScriptFixturesHelpers

  let_it_be(:upstream_project) { create(:project, :public, :repository) }
  let_it_be(:project) { create(:project, :public, :repository, upstream_projects: [upstream_project]) }
  let_it_be(:downstream_project) { create(:project, :public, :repository, upstream_projects: [project]) }
  let_it_be(:user) { create(:user) }

  let(:upstream_query_path) { 'ci/pipeline_subscriptions/graphql/queries/get_upstream_subscriptions.query.graphql' }
  let(:downstream_query_path) { 'ci/pipeline_subscriptions/graphql/queries/get_downstream_subscriptions.query.graphql' }

  before_all do
    project.add_maintainer(user)
    upstream_project.add_maintainer(user)
    downstream_project.add_maintainer(user)
  end

  context 'with upstream pipeline subscriptions' do
    it "graphql/pipeline_subscriptions/upstream.json" do
      query = get_graphql_query_as_string(upstream_query_path, ee: true)

      post_graphql(query, current_user: user, variables: { fullPath: project.full_path })

      expect_graphql_errors_to_be_empty
    end
  end

  context 'with downstream pipeline subscriptions' do
    it "graphql/pipeline_subscriptions/downstream.json" do
      query = get_graphql_query_as_string(downstream_query_path, ee: true)

      post_graphql(query, current_user: user, variables: { fullPath: project.full_path })

      expect_graphql_errors_to_be_empty
    end
  end
end
