# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        module ExplainCode
          class Executor < SlashCommandTool
            extend ::Gitlab::Utils::Override
            include Concerns::AiDependent

            NAME = 'ExplainCode'
            HUMAN_NAME = 'Explain Code'
            DESCRIPTION = 'Useful tool to explain code snippets and blocks.'
            RESOURCE_NAME = nil
            EXAMPLE = "Question: How would you improve the " \
                      "```def hello_world\nputs('Hello, world!\\n\');\nend``` code? " \
                      'Picked tools: "ExplainCode" tool. ' \
                      'Reason: The question has a code block that needs improvement. "ExplainCode" tool ' \
                      'can process this question.'
            PROVIDER_PROMPT_CLASSES = {
              anthropic: ::Gitlab::Llm::Chain::Tools::ExplainCode::Prompts::Anthropic,
              vertex_ai: ::Gitlab::Llm::Chain::Tools::ExplainCode::Prompts::VertexAi
            }.freeze

            PROMPT_TEMPLATE = [
              Utils::Prompt.as_system(
                <<~PROMPT
                  You are a software developer.
                  You can explain code snippets.
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
              Utils::Prompt.as_user('The generated code should be formatted in markdown.'),
              Utils::Prompt.as_user("%<input>s")
            ].freeze

            SLASH_COMMANDS = {
              '/explain' => {
                description: 'Explain the code',
                instruction: 'Explain the code in <code></code> tags.',
                instruction_with_input: 'Explain %<input>s in the code in <code></code> tags.'
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

            def resource_name
              nil
            end
          end
        end
      end
    end
  end
end
