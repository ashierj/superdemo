# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        module ExplainCode
          module Prompts
            class Anthropic
              include Concerns::AnthropicPrompt

              MODEL = 'claude-2.1'

              def self.prompt(variables)
                if variables.fetch(:claude_3_enabled, false)
                  {
                    prompt: Utils::Prompt.role_conversation(
                      Utils::Prompt.format_conversation(
                        ::Gitlab::Llm::Chain::Tools::ExplainCode::Executor::PROMPT_TEMPLATE,
                        variables)
                    )
                  }
                else
                  base_prompt = Utils::Prompt.no_role_text(
                    ::Gitlab::Llm::Chain::Tools::ExplainCode::Executor::PROMPT_TEMPLATE, variables
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
end
