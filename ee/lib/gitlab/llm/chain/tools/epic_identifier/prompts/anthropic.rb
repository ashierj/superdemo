# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        module EpicIdentifier
          module Prompts
            class Anthropic
              def self.prompt(options)
                base_prompt = Utils::Prompt.no_role_text(
                  ::Gitlab::Llm::Chain::Tools::EpicIdentifier::Executor::PROMPT_TEMPLATE, options
                )

                {
                  prompt: "\n\nHuman: #{base_prompt}\n\nAssistant: ```json
                    \{
                      \"ResourceIdentifierType\": \"",
                  options: { model: ::Gitlab::Llm::AiGateway::Client::DEFAULT_INSTANT_MODEL }
                }
              end
            end
          end
        end
      end
    end
  end
end
