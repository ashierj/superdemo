# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Agents
        module ZeroShot
          module Prompts
            class Anthropic < Base
              include Concerns::AnthropicPrompt
              extend Langsmith::RunHelpers

              def self.prompt(options)
                if Feature.enabled?(:ai_claude_3_sonnet, options.fetch(:current_user))
                  history = truncated_conversation_list(options[:conversation])

                  text = history + base_prompt(options)
                else
                  human_role = ROLE_NAMES[Llm::AiMessage::ROLE_USER]

                  text = <<~PROMPT
                  \n\n#{human_role}: #{base_prompt(options)}
                  PROMPT

                  history = truncated_conversation(
                    options[:conversation],
                    Requests::Anthropic::PROMPT_SIZE - text.size
                  )

                  text = [history, text].join if history.present?
                end

                Requests::Anthropic.prompt(text)
              end
              traceable :prompt, name: 'Build prompt', run_type: 'prompt', class_method: true

              def self.truncated_conversation_list(conversation)
                # We save a maximum of 50 chat history messages
                # We save a max of 20k chars for each message prompt (~5k
                # tokens)
                # Response from Anthropic is max of 4096 tokens
                # So the max tokens we would ever send 9k * 50 = 450k tokens.
                # Max context window is 200k.
                # For now, no truncating actually happening here but we should
                # do that to make sure we stay under the limit.
                # https://gitlab.com/gitlab-org/gitlab/-/issues/452608
                return [] if conversation.blank?

                conversation.map do |message, _|
                  { role: message.role.to_sym, content: message.content }
                end
              end

              # Returns messages from previous conversation. To assure that overall prompt size is not too big,
              # we keep adding messages from most-recent to older until we reach overall prompt limit.
              def self.truncated_conversation(conversation, limit)
                return '' if conversation.blank?

                buffer = ''
                conversation.reverse_each.reduce('') do |result, message|
                  role = ROLE_NAMES[message.role]
                  buffer = "\n\n#{role}: #{message.content}#{buffer}"
                  break result if buffer.size + result.size > limit

                  # Anthropic requires prompts to start with a `\n\nHuman:` turn. Thus, we accumulate in `buffer` the
                  # conversation turns while iterating, unitl we encounter a `\n\nHuman:` role, and then we add that
                  # whole conversation block to the history
                  # Ref: https://docs.anthropic.com/claude/reference/prompt-validation
                  next result unless message.role == Llm::AiMessage::ROLE_USER

                  new_str = "#{buffer}#{result}"
                  buffer = '' # Reset the buffer for the next conversation block

                  new_str
                end
              end
            end
          end
        end
      end
    end
  end
end
