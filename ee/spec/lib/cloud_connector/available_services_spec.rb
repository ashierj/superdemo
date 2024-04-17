# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CloudConnector::AvailableServices, feature_category: :cloud_connector do
  describe '.find_by_name', :redis do
    it 'reads available service' do
      available_services = { duo_chat: CloudConnector::AvailableServiceData.new(:duo_chat, nil, nil) }
      expect(described_class.instance).to receive(:read_available_services).and_return(available_services)

      service = described_class.find_by_name(:duo_chat)

      expect(service.name).to eq(:duo_chat)
    end

    context 'when available_services is empty' do
      it 'returns null service data' do
        expect(described_class.instance).to receive(:read_available_services).and_return([])

        service = described_class.find_by_name(:duo_chat)

        expect(service.name).to eq(:missing_service)
        expect(service).to be_instance_of(CloudConnector::MissingServiceData)
      end
    end
  end

  describe '#available_services', :redis do
    subject(:available_services) { described_class.instance.available_services }

    it 'caches the available services' do
      expect(described_class.instance).to receive(:read_available_services).and_call_original.once

      2.times do
        available_services
      end
    end
  end
end
