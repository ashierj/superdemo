# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Agents::ZeroShot::Prompts::VertexAi, feature_category: :duo_chat do
  include FakeBlobHelpers

  describe '.prompt' do
    it 'returns prompt' do
      options = {
        tools_definitions: "tool definitions",
        tool_names: "tool names",
        user_input: 'foo?',
        agent_scratchpad: "some observation",
        prompt_version: ::Gitlab::Llm::Chain::Agents::ZeroShot::Executor::PROMPT_TEMPLATE,
        current_code: "",
        resources: ""
      }
      prompt = described_class.prompt(options)[:prompt]
      prompt_text = "Answer the question as accurate as you can."

      expect(prompt).to include('foo?')
      expect(prompt).to include('tool definitions')
      expect(prompt).to include('tool names')
      expect(prompt).to include(prompt_text)
      expect(prompt).to include(Gitlab::Llm::Chain::Utils::Prompt.default_system_prompt)
    end
  end

  it_behaves_like 'zero shot prompt'
end
