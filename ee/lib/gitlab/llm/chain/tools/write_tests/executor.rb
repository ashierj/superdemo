# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        module WriteTests
          class Executor < SlashCommandTool
            extend ::Gitlab::Utils::Override
            include Concerns::AiDependent

            NAME = 'WriteTests'
            HUMAN_NAME = 'Write Tests'
            DESCRIPTION = 'Useful tool to write tests for source code.'
            RESOURCE_NAME = nil
            EXAMPLE = <<~TEXT
              Question: Write tests for this code
              ```
              def hello_world
                puts('Hello, world!')
              end
              ```
              Picked tools: "WriteTests" tool.
              Reason: The question has a code block for which we want to write tests. "WriteTests" tool can process this question.
            TEXT
            PROVIDER_PROMPT_CLASSES = {
              anthropic: ::Gitlab::Llm::Chain::Tools::WriteTests::Prompts::Anthropic,
              vertex_ai: ::Gitlab::Llm::Chain::Tools::WriteTests::Prompts::VertexAi
            }.freeze

            PROMPT_TEMPLATE = [
              Utils::Prompt.as_system(
                <<~PROMPT
                  You are a software developer.
                  You can write new tests.
                  %<language_info>s
                  Here is the code user selected:
                PROMPT
              ),
              Utils::Prompt.as_user(
                <<~PROMPT
                  <code>
                    %<selected_text>s
                  </code>
                PROMPT
              ),
              Utils::Prompt.as_user("%<input>s")
            ].freeze

            SLASH_COMMANDS = {
              '/tests' => {
                description: 'Write tests for the code',
                instruction: 'Write tests for the code in <code></code> tags.',
                instruction_with_input: 'Write tests %<input>s for the code in <code></code> tags.'
              }
            }.freeze

            def self.slash_commands
              SLASH_COMMANDS
            end

            def perform
              Answer.new(status: :ok, context: context, content: request, tool: nil)
            rescue StandardError
              Answer.error_answer(context: context, content: _("Unexpected error"))
            end

            private

            def authorize
              Utils::Authorizer.context_allowed?(context: context)
            end
          end
        end
      end
    end
  end
end
