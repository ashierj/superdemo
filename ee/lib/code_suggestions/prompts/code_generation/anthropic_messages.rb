# frozen_string_literal: true

module CodeSuggestions
  module Prompts
    module CodeGeneration
      class AnthropicMessages < Anthropic
        GATEWAY_PROMPT_VERSION = 3

        private

        def prompt
          [
            { role: :system, content: system_prompt },
            { role: :user, content: instructions },
            { role: :assistant, content: assistant_prompt }
          ]
        end
      end
    end
  end
end
