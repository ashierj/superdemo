# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TrialDiscoverPageExperiment, :experiment, feature_category: :activation do
  let_it_be(:excluded) { build_stubbed(:user, created_at: Date.new(2024, 1, 1)) }
  let_it_be(:assigned) do
    build_stubbed(:user, created_at: TrialDiscoverPageExperiment::EXCLUDE_USERS_OLDER_THAN)
  end

  shared_examples 'existing_users_are_excluded' do
    it "excludes existing users" do
      expect(experiment(:trial_discover_page, actor: excluded)).to exclude(actor: excluded)
      expect(experiment(:trial_discover_page, actor: assigned)).not_to exclude(actor: assigned)
    end
  end

  context 'with control experience' do
    before do
      stub_experiments(trial_discover_page: :control)
    end

    it 'registers control behavior' do
      expect(experiment(:trial_discover_page, actor: assigned)).to register_behavior(:control).with(nil)
      expect { experiment(:trial_discover_page, actor: assigned).run }.not_to raise_error
    end

    it_behaves_like 'existing_users_are_excluded'
  end

  context 'with candidate experience' do
    before do
      stub_experiments(trial_discover_page: :candidate)
    end

    it 'registers candidate behavior' do
      expect(experiment(:trial_discover_page, actor: assigned)).to register_behavior(:candidate).with(nil)
      expect { experiment(:trial_discover_page, actor: assigned).run }.not_to raise_error
    end

    it_behaves_like 'existing_users_are_excluded'
  end
end
