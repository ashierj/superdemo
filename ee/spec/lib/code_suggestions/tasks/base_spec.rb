# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodeSuggestions::Tasks::Base, feature_category: :code_suggestions do
  subject { described_class.new }

  describe '.base_url' do
    context 'when use_cloud_connector_lb is disabled' do
      before do
        stub_feature_flags(use_cloud_connector_lb: false)
      end

      context 'without CODE_SUGGESTIONS_BASE_URL env var' do
        it 'returns correct URL' do
          expect(described_class.base_url).to eql('https://codesuggestions.gitlab.com')
        end
      end

      context 'with CODE_SUGGESTIONS_BASE_URL env var' do
        before do
          stub_env('CODE_SUGGESTIONS_BASE_URL', 'http://test.local')
        end

        it 'returns correct URL' do
          expect(described_class.base_url).to eql('http://test.local')
        end
      end
    end

    it 'returns correct URL' do
      expect(described_class.base_url).to eql('https://cloud.gitlab.com/ai')
    end
  end

  describe '#endpoint' do
    it 'raies NotImplementedError' do
      expect { subject.endpoint }.to raise_error(NotImplementedError)
    end
  end
end
