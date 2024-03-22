# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SignupIntentStepOneExperiment, :experiment, feature_category: :acquisition do
  let(:user) { build_stubbed(:user) }

  context 'with control experience' do
    before do
      stub_experiments(signup_intent_step_one: :control)
    end

    it 'registers control behavior' do
      expect(experiment(:signup_intent_step_one, actor: user)).to register_behavior(:control).with(nil)
      expect { experiment(:signup_intent_step_one, actor: user).run }.not_to raise_error
    end
  end

  context 'with candidate experience' do
    before do
      stub_experiments(signup_intent_step_one: :candidate)
    end

    it 'registers candidate behavior' do
      expect(experiment(:signup_intent_step_one, actor: user)).to register_behavior(:candidate).with(nil)
      expect { experiment(:signup_intent_step_one, actor: user).run }.not_to raise_error
    end
  end
end
