# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        module ExplainCode
          class Executor < Tool
            extend ::Gitlab::Utils::Override
            include Concerns::AiDependent

            NAME = 'ExplainCode'
            HUMAN_NAME = 'Explain Code'
            DESCRIPTION = 'Useful tool to explain code snippets and blocks.'
            RESOURCE_NAME = 'explain code answer'
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
                PROMPT
              ),
              Utils::Prompt.as_user("%<input>s"),
              Utils::Prompt.as_user(
                <<~PROMPT
                  <code>
                    %<selected_text>s
                  </code>
                PROMPT
              )
            ].freeze

            SLASH_COMMANDS = {
              '/explain' => {
                description: 'Explain the code',
                instruction: 'Explain the code below in <code></code> tags.',
                instruction_with_input: 'Explain %<input>s in the code below in <code></code> tags.'
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
              RESOURCE_NAME
            end

            override :prompt_options
            def prompt_options
              file = context.current_file || {}

              opts = super.merge(
                language_info: '',
                selected_text: file[:selected_text].to_s
              )

              filename = file[:file_name].to_s
              language = ::CodeSuggestions::ProgrammingLanguage.detect_from_filename(filename)
              if language.name.present?
                opts[:language_info] = "The code is written in #{language.name} and stored as #{filename}"
              end

              opts
            end
          end
        end
      end
    end
  end
end
