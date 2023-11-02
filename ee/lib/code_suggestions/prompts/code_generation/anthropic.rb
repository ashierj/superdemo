# frozen_string_literal: true

module CodeSuggestions
  module Prompts
    module CodeGeneration
      class Anthropic < CodeSuggestions::Prompts::Base
        GATEWAY_PROMPT_VERSION = 2
        # claude-2 max_input_tokens is 100K tokens, token =~ 4 characters, 1000 tokens are left for prompt itself
        MAX_INPUT_CHARS = 99000 * 4

        def request_params
          {
            model_provider: ::CodeSuggestions::TaskFactory::ANTHROPIC,
            prompt_version: GATEWAY_PROMPT_VERSION,
            prompt: prompt
          }
        end

        private

        def prompt
          <<~PROMPT


            Human: You are a code completion AI that writes high-quality code like a senior engineer.
            You are looking at '#{file_path_info}' file. You write code in between tags as in this example:

            <new_code>
            // Code goes here
            </new_code>

            This is a task to write new #{language.name} code in a file '#{file_path_info}', based on a given description.
            #{existing_code_instruction}
            You get the description of the code that needs to be created in <instruction> XML tags.

            It is your task to write valid and working #{language.name} code.
            Only return in your response new code.
            Do not provide any explanation.

            #{existing_code_block}

            <instruction>
              #{params[:instruction]}
            </instruction>


            Assistant: <new_code>
          PROMPT
        end

        def existing_code_instruction
          return unless params[:prefix].present?

          "You get the already existing code file in <existing_code> XML tags."
        end

        def existing_code_block
          return unless params[:prefix].present?

          <<~CODE
            <existing_code>
            #{params[:prefix].last(MAX_INPUT_CHARS)}
            </existing_code>
          CODE
        end
      end
    end
  end
end
