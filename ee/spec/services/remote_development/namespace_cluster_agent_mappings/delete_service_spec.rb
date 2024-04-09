# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::NamespaceClusterAgentMappings::DeleteService, feature_category: :remote_development do
  let(:agent) { instance_double(Clusters::Agent) }
  let(:group) { instance_double(Group) }

  describe '#execute' do
    subject(:service_response) do
      described_class.new.execute(namespace: group, cluster_agent: agent)
    end

    before do
      allow(RemoteDevelopment::NamespaceClusterAgentMappings::Delete::Main)
        .to receive(:main).with(namespace: group, cluster_agent: agent)
          .and_return(response_hash)
    end

    context 'when success' do
      let(:response_hash) do
        {
          status: :success,
          payload: {}
        }
      end

      it 'returns a success ServiceResponse' do
        expect(service_response).to be_success
        expect(service_response.payload).to be_empty
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
