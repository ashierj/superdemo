# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CloudConnector::Access, models: true, feature_category: :cloud_connector do
  describe 'validations' do
    let_it_be(:cloud_connector_access) { create(:cloud_connector_access) }

    subject { cloud_connector_access }

    it { is_expected.to validate_presence_of(:data) }
  end

  describe '.service_start_date_for' do
    context 'with empty table' do
      it 'returns nil' do
        expect(described_class.service_start_date_for('gitlab')).to be_nil
      end
    end

    context 'with data' do
      let(:service_start_time) { DateTime.new(2024, 1, 29, 12, 0, 0).to_s }
      let(:data) { { available_services: [{ name: "duo_chat", serviceStartTime: service_start_time }] } }
      let!(:cloud_connector_access) { create(:cloud_connector_access, data: data) }

      context 'with service defined' do
        it 'returns the service start time' do
          expect(described_class.service_start_date_for('duo_chat')).to eq(service_start_time)
        end
      end

      context 'without service defined' do
        it 'returns the service start time' do
          expect(described_class.service_start_date_for('gitlab')).to be_nil
        end
      end

      context 'without service start date' do
        let(:service_start_time) { nil }

        it 'returns nil' do
          expect(described_class.service_start_date_for('duo_chat')).to be_nil
        end
      end
    end
  end
end
