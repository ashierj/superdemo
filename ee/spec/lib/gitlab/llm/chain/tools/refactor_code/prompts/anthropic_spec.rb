# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Tools::RefactorCode::Prompts::Anthropic, feature_category: :duo_chat do
  describe '.prompt' do
    it 'returns prompt', :aggregate_failures do
      result = described_class.prompt(
        input: 'question',
        language_info: 'language',
        selected_text: 'selected text',
        file_content: 'file content',
        file_content_reuse: 'code reuse note'
      )
      prompt = result[:prompt]
      model = result[:options][:model]
      expected_prompt = <<~PROMPT.chomp


        Human: You are a software developer.
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

        Assistant:
      PROMPT

      expect(prompt).to include(expected_prompt)
      expect(model).to eq(described_class::MODEL)
    end
  end
end
