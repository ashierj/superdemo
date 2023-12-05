# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Anthropic::ResponseModifiers::CategorizeQuestion, feature_category: :duo_chat do
  subject(:response_modifier) { described_class.new(nil) }

  it 'returns empty errors' do
    expect(response_modifier.errors).to be_empty
  end

  context 'when error is present' do
    subject(:response_modifier) { described_class.new(error: 'error') }

    it 'returns empty errors' do
      expect(response_modifier.errors).to eq(['error'])
    end
  end
end
