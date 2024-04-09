# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        module WriteTests
          module Prompts
            class Anthropic
              include Concerns::AnthropicPrompt

              MODEL = 'claude-2.1'

              def self.prompt(variables)
                base_prompt = Utils::Prompt.no_role_text(
                  ::Gitlab::Llm::Chain::Tools::WriteTests::Executor::PROMPT_TEMPLATE, variables
                )
                {
                  prompt: "\n\nHuman: #{base_prompt}\n\nAssistant:",
                  options: { model: MODEL }
                }
              end
            end
          end
        end
      end
    end
  end
end
