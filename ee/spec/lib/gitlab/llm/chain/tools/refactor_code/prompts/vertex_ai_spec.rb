# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Tools::RefactorCode::Prompts::VertexAi, feature_category: :duo_chat do
  describe '.prompt' do
    it 'returns prompt' do
      prompt = described_class
        .prompt({ input: 'question', language_info: 'language', selected_text: 'selected text',
                  file_content: 'file content', file_content_reuse: 'code reuse note' })[:prompt]
      expected_prompt = <<~PROMPT.chomp
        You are a software developer.
        You can refactor code.
        language

        file content
        In the file user selected this code:
        <selected_code>
          selected text
        </selected_code>

        question
        code reuse note
        Any code blocks in response should be formatted in markdown.
      PROMPT

      expect(prompt).to eq(expected_prompt)
    end
  end
end
