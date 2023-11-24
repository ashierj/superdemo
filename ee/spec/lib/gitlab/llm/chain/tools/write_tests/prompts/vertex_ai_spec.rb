# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Tools::WriteTests::Prompts::VertexAi, feature_category: :duo_chat do
  describe '.prompt' do
    it 'returns prompt' do
      prompt = described_class
        .prompt({ input: 'foo', language_info: 'language', selected_text: 'selected text' })[:prompt]
      expected_prompt = <<~PROMPT
        You are a software developer.
        You can write new tests.
        language

        foo
        <code>
          selected text
        </code>
      PROMPT

      expect(prompt).to eq(expected_prompt)
    end
  end
end
