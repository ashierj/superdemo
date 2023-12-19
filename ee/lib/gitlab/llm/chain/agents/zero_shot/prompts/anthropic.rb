# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Agents
        module ZeroShot
          module Prompts
            class Anthropic < Base
              include Concerns::AnthropicPrompt

              def self.prompt(options)
                human_role = ROLE_NAMES[Llm::AiMessage::ROLE_USER]

                text = <<~PROMPT
                  #{human_role}: #{base_prompt(options)}
                PROMPT

                history = truncated_conversation(options[:conversation], Requests::Anthropic::PROMPT_SIZE - text.size)
                text = [history, text].join if history.present?

                Requests::Anthropic.prompt(text)
              end

              # Returns messages from previous conversation. To assure that overall prompt size is not too big,
              # we keep adding messages from most-recent to older until we reach overall prompt limit.
              def self.truncated_conversation(conversation, limit)
                return '' if conversation.blank?

                result = ''
                conversation.reverse_each do |message|
                  role = ROLE_NAMES[message.role]
                  new_str = "#{role}: #{message.content}\n\n#{result}"
                  break if limit < new_str.size

                  result = new_str
                end

                result
              end
            end
          end
        end
      end
    end
  end
end
