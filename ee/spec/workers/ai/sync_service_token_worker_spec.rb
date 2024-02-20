# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ai::SyncServiceTokenWorker, type: :worker, feature_category: :cloud_connector do
  describe '#perform' do
    let(:service_response) { ServiceResponse.success }

    before do
      allow(CloudConnector::SyncCloudConnectorAccessService).to receive_message_chain(:new,
        :execute).and_return(service_response)
    end

    include_examples 'an idempotent worker' do
      let(:worker) { described_class.new }

      subject(:sync_service_token) { perform_multiple(worker: worker) }

      it 'executes the SyncCloudConnectorAccessService with expected params' do
        expect(CloudConnector::SyncCloudConnectorAccessService).to receive_message_chain(:new, :execute)
        expect(worker).not_to receive(:log_extra_metadata_on_done)

        sync_service_token
      end

      context 'when SyncCloudConnectorAccessService fails' do
        let(:service_response) { ServiceResponse.error(message: 'Error') }

        it { expect { sync_service_token }.not_to raise_error }

        it 'logs the error' do
          expect(worker).to receive(:log_extra_metadata_on_done)
                               .with(:error_message, service_response[:message]).twice

          sync_service_token
        end
      end
    end
  end
end
