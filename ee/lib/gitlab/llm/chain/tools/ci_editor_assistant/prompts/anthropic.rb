# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        module CiEditorAssistant
          module Prompts
            class Anthropic
              include Concerns::AnthropicPrompt

              MODEL = 'claude-2.1'

              def self.prompt(options)
                template = ::Gitlab::Llm::Chain::Tools::CiEditorAssistant::Executor::PROMPT_TEMPLATE.dup
                template << Utils::Prompt.as_assistant('```yaml')
                base_prompt = Utils::Prompt.role_text(template, options, roles: ROLE_NAMES)

                {
                  prompt: base_prompt,
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
