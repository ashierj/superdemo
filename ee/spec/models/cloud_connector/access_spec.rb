# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CloudConnector::Access, models: true, feature_category: :cloud_connector do
  describe 'validations' do
    let_it_be(:cloud_connector_access) { create(:cloud_connector_access) }

    subject { cloud_connector_access }

    it { is_expected.to validate_presence_of(:data) }
  end

  describe 'callbacks' do
    describe 'after_save' do
      subject(:access) { build(:cloud_connector_access) }

      it 'calls #clear_available_services_cache!' do
        is_expected.to receive(:clear_available_services_cache!)
        access.save!
      end
    end
  end

  describe '#clear_available_services_cache!', :use_clean_rails_memory_store_caching do
    let(:cache_key) { CloudConnector::AvailableServices::CLOUD_CONNECTOR_SERVICES_KEY }

    before do
      Rails.cache.write(cache_key, double)
    end

    it 'clears cache' do
      access = create(:cloud_connector_access)

      access.clear_available_services_cache!

      expect(Rails.cache.read(cache_key)).to be_nil
    end
  end
end
