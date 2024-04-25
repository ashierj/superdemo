# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.namespace.remote_development_cluster_agents(filter: AVAILABLE)',
  feature_category: :remote_development do
  include GraphqlHelpers
  include StubFeatureFlags

  let_it_be(:user) { create(:user) }
  let(:stub_finder_response) { [agent] }
  let_it_be(:current_user) { user }
  # Setup cluster and user such that the user has the bare minimum permissions
  # to be able to receive the agent when calling the API i.e. the user has Developer access
  # to the agent project ONLY (and not a group-level access)
  let_it_be(:agent) do
    create(:ee_cluster_agent, :in_group, :with_remote_development_agent_config).tap do |agent|
      agent.project.add_developer(user)
    end
  end

  let_it_be(:namespace) { agent.project.namespace }
  let_it_be(:namespace_agent_mapping) do
    create(
      :remote_development_namespace_cluster_agent_mapping,
      user: user,
      agent: agent,
      namespace: namespace
    )
  end

  let(:fields) do
    <<~QUERY
      nodes {
        #{all_graphql_fields_for('cluster_agents'.classify, max_depth: 1)}
      }
    QUERY
  end

  let(:agent_names_in_response) { subject.pluck('name') }
  let(:query) do
    graphql_query_for(
      :namespace,
      { full_path: namespace.full_path },
      query_graphql_field(
        :remote_development_cluster_agents,
        { filter: :AVAILABLE },
        fields
      )
    )
  end

  subject { graphql_data.dig('namespace', 'remoteDevelopmentClusterAgents', 'nodes') }

  before do
    stub_licensed_features(remote_development: true)
  end

  context 'when the params are valid' do
    it 'returns a cluster agent' do
      post_graphql(query, current_user: current_user)

      expect(agent_names_in_response).to eq([agent.name])
    end
  end

  context 'when remote_development feature is unlicensed' do
    before do
      stub_licensed_features(remote_development: false)
    end

    it 'returns an error' do
      post_graphql(query, current_user: current_user)

      expect_graphql_errors_to_include "'remote_development' licensed feature is not available"
    end
  end

  context 'when the feature flag is disabled' do
    before do
      stub_feature_flags(remote_development_namespace_agent_authorization: false)
    end

    it 'returns an error' do
      post_graphql(query, current_user: current_user)

      expect_graphql_errors_to_include "'remote_development_namespace_agent_authorization' feature flag is disabled"
    end
  end

  context 'when the provided namespace is not a group namespace' do
    let(:namespace) { agent.project.project_namespace }

    it 'returns an error' do
      post_graphql(query, current_user: current_user)

      expect_graphql_errors_to_include "does not exist or you don't have permission to perform this action"
    end
  end

  context 'when user does not have access to the project' do
    # simulate test conditions by creating the maximum privileged user that does/should
    # not have the permission to access the agent
    let(:current_user) do
      create(:user).tap do |user|
        agent.project.add_reporter(user)
      end
    end

    it 'skips agents for which the user does not have access' do
      post_graphql(query, current_user: current_user)

      expect(agent_names_in_response).to eq([])
    end
  end
end
