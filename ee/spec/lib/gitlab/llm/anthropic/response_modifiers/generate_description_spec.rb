# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Anthropic::ResponseModifiers::GenerateDescription, feature_category: :team_planning do
  subject(:response_modifier) { described_class.new(ai_response) }

  let(:ai_response) { { 'completion' => 'foobar' }.to_json }

  it 'extracts completion' do
    expect(response_modifier.response_body).to eq('foobar')
  end

  it 'returns empty errors' do
    expect(response_modifier.errors).to be_empty
  end

  context 'when error is present' do
    let(:ai_response) { { error: { message: 'error' } }.to_json }

    it 'returns empty errors' do
      expect(response_modifier.errors).to eq(['error'])
    end
  end
end
