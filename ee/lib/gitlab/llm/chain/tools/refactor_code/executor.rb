# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        module RefactorCode
          class Executor < SlashCommandTool
            extend ::Gitlab::Utils::Override
            include Concerns::AiDependent

            NAME = 'RefactorCode'
            HUMAN_NAME = 'Refactor Code'
            DESCRIPTION = 'Useful tool to refactor source code.'
            RESOURCE_NAME = nil
            EXAMPLE = <<~TEXT
              Question: Refactor the following code
              ```
              def hello_world
                puts('Hello, world!')
              end
              ```
              Picked tools: "RefactorCode" tool.
              Reason: The question has a code block which we want to refactor. "RefactorCode" tool can process this question.
            TEXT
            PROVIDER_PROMPT_CLASSES = {
              anthropic: ::Gitlab::Llm::Chain::Tools::RefactorCode::Prompts::Anthropic,
              vertex_ai: ::Gitlab::Llm::Chain::Tools::RefactorCode::Prompts::VertexAi
            }.freeze

            PROMPT_TEMPLATE = [
              Utils::Prompt.as_system(
                <<~PROMPT
                  You are a software developer.
                  You can refactor code.
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
              '/refactor' => {
                description: 'Refactor the code',
                instruction: 'Refactor the code in <code></code> tags.',
                instruction_with_input: 'Refactor %<input>s in the code in <code></code> tags.'
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
