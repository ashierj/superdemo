# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Tools::WriteTests::Prompts::VertexAi, feature_category: :duo_chat do
  describe '.prompt' do
    it 'returns prompt' do
      prompt = described_class
        .prompt({ input: 'question', language_info: 'language', selected_text: 'selected text',
                  file_content: 'file content' })[:prompt]
      expected_prompt = <<~PROMPT.chomp
        You are a software developer.
        You can write new tests.
        language

        file content
        In the file user selected this code:
        <selected_code>
          selected text
        </selected_code>

        question
        Any code blocks in response should be formatted in markdown.
      PROMPT

      expect(prompt).to eq(expected_prompt)
    end
  end
end
