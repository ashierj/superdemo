# frozen_string_literal: true

require "spec_helper"

RSpec.describe RemoteDevelopment::ClusterAgentsFinder, feature_category: :remote_development do
  let_it_be(:user) { create(:user) }
  let_it_be(:root_agent) { create(:ee_cluster_agent, :with_remote_development_agent_config) }
  let_it_be(:nested_agent) { create(:ee_cluster_agent, :with_remote_development_agent_config) }
  let_it_be_with_reload(:root_namespace) do
    create(:group,
      projects: [root_agent.project],
      children: [
        create(:group,
          projects: [nested_agent.project]
        )
      ]
    )
  end

  let(:nested_namespace) { root_namespace.children.first }
  let(:namespace) { root_namespace }
  let(:filter) { :available }

  before_all do
    create(
      :remote_development_namespace_cluster_agent_mapping,
      user: user,
      agent: nested_agent,
      namespace: root_namespace
    )
  end

  subject(:response) do
    described_class.execute(
      namespace: namespace,
      filter: filter
    ).to_a
  end

  context 'with filter_type set to available' do
    context 'when all cluster agents are bound to the namespace' do
      it 'returns all cluster agents passed in the parameters' do
        expect(response).to eq([nested_agent])
      end
    end

    context 'when cluster agents are bound to ancestors of the namespace' do
      let(:namespace) { nested_namespace }

      it 'returns cluster agents including those bound to the ancestors' do
        expect(response).to eq([nested_agent])
      end
    end

    context 'when the same cluster agent is bound to a namespace as well as its ancestors' do
      # Set this up in a way such that same agent is mapped to two namespaces:
      # the namespace in the request as well as its ancestor
      before do
        create(
          :remote_development_namespace_cluster_agent_mapping,
          user: user,
          namespace: nested_namespace,
          agent: nested_agent
        )
      end

      let(:namespace) { nested_namespace }

      it 'returns distinct cluster agents in the response' do
        expect(response).to eq([nested_agent])
      end
    end

    context 'when a bound cluster agent does not have remote development enabled' do
      before do
        nested_agent.remote_development_agent_config.update!(enabled: false)
      end

      it 'ignores agents with remote development disabled in the response' do
        expect(response).to eq([])
      end
    end
  end

  context 'with an invalid value for filter_type' do
    let(:filter) { "some_invalid_value" }

    it 'raises a RuntimeError' do
      expect { response }.to raise_error(RuntimeError, "Unsupported value for filter: #{filter}")
    end
  end
end
