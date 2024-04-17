# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        module IssueReader
          module Prompts
            class Anthropic
              include Concerns::AnthropicPrompt
              def self.prompt(options)
                base_prompt = Utils::Prompt.no_role_text(
                  ::Gitlab::Llm::Chain::Tools::IssueIdentifier::Executor::PROMPT_TEMPLATE, options
                )

                Requests::Anthropic.prompt(
                  "\n\nHuman: #{base_prompt}\n\nAssistant: ```json
                    \{
                      \"ResourceIdentifierType\": \"",
                  options: { model: ::Gitlab::Llm::AiGateway::Client::DEFAULT_INSTANT_MODEL }
                )
              end
            end
          end
        end
      end
    end
  end
end
