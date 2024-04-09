# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateZoektSettingsInApplicationSettings, feature_category: :global_search do
  let!(:application_setting) { table(:application_settings).create! }

  describe '#up' do
    context 'when zoekt_settings is not already set' do
      it 'migrates zoekt_settings from the feature flags in the application_settings successfully' do
        expected_zoekt_settings = {
          'zoekt_indexing_enabled' => Feature.enabled?(:index_code_with_zoekt),
          'zoekt_indexing_paused' => Feature.enabled?(:zoekt_pause_indexing, type: :ops),
          'zoekt_search_enabled' => Feature.enabled?(:search_code_with_zoekt)
        }
        expect { migrate! }.to change { application_setting.reload.zoekt_settings }.from({}).to(expected_zoekt_settings)
      end
    end

    context 'when zoekt_settings is already set' do
      before do
        application_setting.update!(zoekt_settings: { zoekt_indexing_enabled: false,
                                                      zoekt_indexing_paused: false, zoekt_search_enabled: false })
      end

      it 'does not update the zoekt_settings' do
        expect(application_setting.zoekt_settings).not_to eq({})
        expect { migrate! }.not_to change { application_setting.reload.zoekt_settings }
      end
    end
  end
end
