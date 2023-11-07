# frozen_string_literal: true

module CodeSuggestions
  module Prompts
    module CodeCompletion
      class Anthropic < CodeSuggestions::Prompts::Base
        GATEWAY_PROMPT_VERSION = 2
        # claude-instant-1 max_input_tokens is 100K tokens, token =~ 4 characters,
        # 1000 tokens are left for prompt itself
        MAX_INPUT_CHARS = 99000 * 4

        def request_params
          {
            model_provider: ::CodeSuggestions::TaskFactory::ANTHROPIC,
            prompt: prompt,
            prompt_version: GATEWAY_PROMPT_VERSION
          }
        end

        private

        def prompt
          trimmed_prefix = prefix.to_s.last(MAX_INPUT_CHARS)
          trimmed_suffix = suffix.to_s.first(MAX_INPUT_CHARS - trimmed_prefix.size)

          <<~PROMPT
            Human: You are a coding autocomplete agent. We want to generate new #{language.name} code inside the file '#{file_path_info}'.
            The existing code is provided in <existing_code></existing_code> tags.
            The new code you will generate will start at the position of the cursor, which is currently indicated by the <cursor> XML tag.
            In your process, first, review the existing code to understand its logic and format. Then, try to determine the most likely new code to generate at the cursor position.
            When generating the new code, please ensure the following:
            1. It is valid #{language.name} code.
            2. It matches the existing code's variable, parameter and function names.
            3. It does not repeat any existing code. Do not repeat code that comes before or after the cursor tags. This includes cases where the cursor is in the middle of a word.
            4. If the cursor is in the middle of a word, it finishes the word instead of repeating code before the cursor tag.
            Return new code enclosed in <new_code></new_code> tags. We will then insert this at the <cursor> position.
            If you are not able to write code based on the given instructions return an empty result like <new_code></new_code>.

            #{examples_section}

            <existing_code>
              #{trimmed_prefix}<cursor>#{trimmed_suffix}
            </existing_code>

            Assistant: <new_code>
          PROMPT
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

          examples_array = language.completion_examples
          return if examples_array.empty?

          ERB.new(examples_template).result(binding)
        end
      end
    end
  end
end
