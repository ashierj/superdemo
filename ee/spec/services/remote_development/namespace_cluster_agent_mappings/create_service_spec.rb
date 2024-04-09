# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::NamespaceClusterAgentMappings::CreateService, feature_category: :remote_development do
  let(:agent) { instance_double(Clusters::Agent) }
  let(:group) { instance_double(Group) }
  let(:creator) { instance_double(User) }
  let(:namespace_agent_mapping) { build_stubbed(:remote_development_namespace_cluster_agent_mapping) }

  describe '#execute' do
    subject(:service_response) do
      described_class.new.execute(namespace: group, cluster_agent: agent, user: creator)
    end

    before do
      allow(RemoteDevelopment::NamespaceClusterAgentMappings::Create::Main)
          .to receive(:main).with(namespace: group, cluster_agent: agent, user: creator)
          .and_return(response_hash)
    end

    context 'when success' do
      let(:response_hash) do
        {
          status: :success,
          payload: {
            namespace_cluster_agent_mapping: namespace_agent_mapping
          }
        }
      end

      it 'returns a success ServiceResponse' do
        expect(service_response).to be_success
        expect(service_response.payload.fetch(:namespace_cluster_agent_mapping)).to eq(namespace_agent_mapping)
      end
    end

    context 'when error' do
      let(:response_hash) { { status: :error, message: 'error', reason: :bad_request } }

      it 'returns an error success ServiceResponse' do
        expect(service_response).to be_error
        service_response => { message:, reason: }
        expect(message).to eq('error')
        expect(reason).to eq(:bad_request)
      end
    end
  end
end
