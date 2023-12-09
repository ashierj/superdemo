# frozen_string_literal: true

module CodeSuggestions
  module Prompts
    module CodeGeneration
      class VertexAi < CodeSuggestions::Prompts::Base
        GATEWAY_PROMPT_VERSION = 2
        # code-bison max_input_tokens=6144, token =~ 4 characters, 344 tokens are left for prompt itself
        # https://cloud.google.com/vertex-ai/docs/generative-ai/learn/models
        MAX_INPUT_CHARS = 5800 * 4

        def request_params
          {
            prompt_version: GATEWAY_PROMPT_VERSION,
            prompt: prompt
          }
        end

        private

        def prompt
          <<~PROMPT
            This is a task to write new #{language.name} code in a file '#{file_path_info}' based on a given description.
            #{existing_code_instruction}
            It is your task to write valid and working #{language.name} code.
            Only return in your response new code.
            #{existing_code_block}

            Create new code for the following description:
            #{instructions}
          PROMPT
        end

        def existing_code_instruction
          return unless params[:prefix].present?

          "You get first the already existing code file and then the description of the code that needs to be created."
        end

        def existing_code_block
          return unless params[:prefix].present?

          <<~CODE

            Already existing code:

            ```#{extension}
            #{params[:prefix].last(MAX_INPUT_CHARS)}
            ```
          CODE
        end

        def instructions
          params[:instruction].presence || 'Generate the most likely code based on instructions.'
        end
      end
    end
  end
end
