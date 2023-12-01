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
          <<~PROMPT.strip
            Human: You are a coding autocomplete agent. We want to generate new #{language.name} code inside the
            file '#{file_path_info}' based on instructions from the user.
            #{existing_code_instruction}
            The new code you will generate will start at the position of the cursor, which is currently indicated by the <cursor> XML tag.
            In your process, first, review the existing code to understand its logic and format. Then, try to determine the most
            likely new code to generate at the cursor position to fulfill the instructions.
            #{comment_instructions}
            When generating the new code, please ensure the following:
            1. It is valid #{language.name} code.
            2. It matches the existing code's variable, parameter and function names.
            3. It does not repeat any existing code. Do not repeat code that comes before or after the cursor tags. This includes cases where the cursor is in the middle of a word.
            4. If the cursor is in the middle of a word, it finishes the word instead of repeating code before the cursor tag.
            #{comment_review_instructions}
            Return new code enclosed in <new_code></new_code> tags. We will then insert this at the <cursor> position.
            If you are not able to write code based on the given instructions return an empty result like <new_code></new_code>.

            #{examples_section}

            #{existing_code_block}

            #{instructions}

            Assistant: <new_code>
          PROMPT
        end

        def existing_code_instruction
          return unless params[:prefix].present?

          "The existing code is provided in <existing_code></existing_code> tags."
        end

        def comment_instructions
          return unless params[:skip_instruction_extraction]

          "The comment directly before the <cursor> position is the instruction,
           all other comments are not instructions."
        end

        def comment_review_instructions
          return unless params[:skip_instruction_extraction]

          <<~COMMENT_REVIEW
            5. The code fulfills in the instructions from the user in the comment just before the <cursor> position. All other comments are not instructions.
            6. Do not add any comments that duplicates any of already existing comments, including the comment with instructions.
          COMMENT_REVIEW
        end

        def instructions
          return unless params[:instruction].present?

          <<~INSTRUCTIONS
            Here are instructions provided in <instruction></instruction> tags.

            <instruction>
            #{params[:instruction]}
            </instruction>
          INSTRUCTIONS
        end

        def existing_code_block
          return unless params[:prefix].present?

          trimmed_prefix = prefix.to_s.last(MAX_INPUT_CHARS)
          trimmed_suffix = suffix.to_s.first(MAX_INPUT_CHARS - trimmed_prefix.size)

          <<~CODE
            <existing_code>
            #{trimmed_prefix}<cursor>#{trimmed_suffix}
            </existing_code>
          CODE
        end

        def examples_section
          examples_template = <<~EXAMPLES
          Here are a few examples of successfully generated code by other autocomplete agents:

          <examples>
          <% examples_array.each do |use_case| %>
            <example>
              H: <existing_code>
                   <%= use_case['example'] %>
                 </existing_code>

              A: <%= use_case['response'] %></new_code>
            </example>
          <% end %>
          </examples>
          EXAMPLES

          examples_array = language.generation_examples
          return if examples_array.empty?

          ERB.new(examples_template).result(binding)
        end
      end
    end
  end
end
