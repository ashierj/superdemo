# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CloudConnector::SelfManaged::AccessDataReader, feature_category: :cloud_connector do
  describe '#read_available_services' do
    let_it_be(:cs_cut_off_date) { Time.zone.parse("2024-02-15 00:00:00 UTC").utc }
    let_it_be(:cs_bundled_with) { %w[duo_pro] }
    let_it_be(:duo_chat_bundled_with) { %w[duo_pro duo_extra] }
    let_it_be(:data) do
      {
        available_services: [
          {
            "name" => "code_suggestions",
            "serviceStartTime" => cs_cut_off_date.to_s,
            "bundledWith" => cs_bundled_with
          },
          {
            "name" => "duo_chat",
            "serviceStartTime" => nil,
            "bundledWith" => duo_chat_bundled_with
          }
        ]
      }
    end

    let_it_be(:cloud_connector_access) { create(:cloud_connector_access, data: data) }
    let_it_be(:available_service_data_class) { CloudConnector::AvailableServiceData }
    let_it_be(:arguments_map) do
      {
        code_suggestions: [cs_cut_off_date, cs_bundled_with],
        duo_chat: [nil, duo_chat_bundled_with]
      }
    end

    subject(:available_services) do
      described_module = described_class
      Class.new { include described_module }.new.read_available_services
    end

    it 'creates AvailableServiceData with correct params' do
      arguments_map.each do |name, args|
        expect(available_service_data_class).to receive(:new).with(name, *args).and_call_original
      end

      available_services
    end

    it 'returns a hash containing all available services', :aggregate_failures do
      expect(available_services.keys).to match_array(arguments_map.keys)

      expect(available_services.values).to all(be_instance_of(available_service_data_class))
    end
  end
end
