# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuesMrsEmptyStateExperiment, :experiment, feature_category: :activation do
  context 'with control experience' do
    before do
      stub_experiments(issues_mrs_empty_state: :control)
    end

    it 'registers control behavior' do
      expect(experiment(:issues_mrs_empty_state)).to register_behavior(:control).with(nil)
      expect { experiment(:issues_mrs_empty_state).run }.not_to raise_error
    end
  end

  context 'with candidate experience' do
    before do
      stub_experiments(issues_mrs_empty_state: :candidate)
    end

    it 'registers candidate behavior' do
      expect(experiment(:issues_mrs_empty_state)).to register_behavior(:candidate).with(nil)
      expect { experiment(:issues_mrs_empty_state).run }.not_to raise_error
    end
  end
end
