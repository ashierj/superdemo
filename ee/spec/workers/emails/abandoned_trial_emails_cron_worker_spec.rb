# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::AbandonedTrialEmailsCronWorker, :saas, feature_category: :onboarding do
  describe "#perform" do
    subject(:worker) { described_class.new }

    it 'does not deliver abandoned trial notification' do
      expect(Notify).not_to receive(:abandoned_trial_notification)

      worker.perform
    end
  end
end
