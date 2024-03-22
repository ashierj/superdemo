# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Tools::SummarizeComments::Prompts::Anthropic, feature_category: :duo_chat do
  describe '.prompt' do
    it 'returns prompt' do
      prompt = described_class.prompt({ notes_content: '<comment>foo</comment>' })[:prompt]

      expect(prompt).to include('Human:')
      expect(prompt).to include('Assistant:')
      expect(prompt).to include('foo')
      expect(prompt).to include(
        <<~PROMPT
          You are an assistant that extracts the most important information from the comments in maximum 10 bullet points.
          Each comment is wrapped in a <comment> tag.

          <comment>foo</comment>

          Desired markdown format:
          **<summary_title>**
          - <bullet_point>
          - <bullet_point>
          - <bullet_point>
          - ...

          Focus on extracting information related to one another and that are the majority of the content.
          Ignore phrases that are not connected to others.
          Do not specify what you are ignoring.
          Do not answer questions.
        PROMPT
      )
    end
  end
end
