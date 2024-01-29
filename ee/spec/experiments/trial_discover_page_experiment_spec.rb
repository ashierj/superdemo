# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TrialDiscoverPageExperiment, :experiment, feature_category: :activation do
  context 'with control experience' do
    before do
      stub_experiments(trial_discover_page: :control)
    end

    it 'registers control behavior' do
      expect(experiment(:trial_discover_page)).to register_behavior(:control).with(nil)
      expect { experiment(:trial_discover_page).run }.not_to raise_error
    end
  end

  context 'with candidate experience' do
    before do
      stub_experiments(trial_discover_page: :candidate)
    end

    it 'registers candidate behavior' do
      expect(experiment(:trial_discover_page)).to register_behavior(:candidate).with(nil)
      expect { experiment(:trial_discover_page).run }.not_to raise_error
    end
  end
end
