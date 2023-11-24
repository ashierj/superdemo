# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Tools::WriteTests::Prompts::Anthropic, feature_category: :duo_chat do
  describe '.prompt' do
    it 'returns prompt' do
      prompt = described_class
        .prompt({ input: 'foo', language_info: 'language', selected_text: 'selected text' })[:prompt]
      expected_prompt = <<~PROMPT.chomp


        Human: You are a software developer.
        You can write new tests.
        language

        foo
        <code>
          selected text
        </code>


        Assistant:
      PROMPT

      expect(prompt).to include(expected_prompt)
    end
  end
end
