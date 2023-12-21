# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admin::ApplicationSettingsHelper, feature_category: :code_suggestions do
  describe 'AI-Powered features settings for Self-Managed instances' do
    describe '#ai_powered_description' do
      subject { helper.ai_powered_description }

      it { is_expected.to include 'https://docs.gitlab.com/ee/user/ai_features.html' }
    end

    describe '#ai_powered_testing_agreement' do
      subject { helper.ai_powered_testing_agreement }

      it { is_expected.to include 'https://about.gitlab.com/handbook/legal/testing-agreement/' }
    end
  end
end
