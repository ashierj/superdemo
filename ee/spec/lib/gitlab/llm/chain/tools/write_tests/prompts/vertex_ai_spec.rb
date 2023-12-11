# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Tools::WriteTests::Prompts::VertexAi, feature_category: :duo_chat do
  describe '.prompt' do
    it 'returns prompt' do
      prompt = described_class
        .prompt({ input: 'question', language_info: 'language', selected_text: 'selected text' })[:prompt]
      expected_prompt = <<~PROMPT.chomp
        You are a software developer.
        You can write new tests.
        language
        Here is the code user selected:

        <code>
          selected text
        </code>

        The generated code should be formatted in markdown.
        question
      PROMPT

      expect(prompt).to eq(expected_prompt)
    end
  end
end
