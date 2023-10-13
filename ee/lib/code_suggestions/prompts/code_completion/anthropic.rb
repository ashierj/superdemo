# frozen_string_literal: true

module CodeSuggestions
  module Prompts
    module CodeCompletion
      class Anthropic < CodeSuggestions::Prompts::Base
        GATEWAY_PROMPT_VERSION = 2

        def request_params
          {
            model_provider: ::CodeSuggestions::AiModels::ANTHROPIC,
            prompt: prompt,
            prompt_version: GATEWAY_PROMPT_VERSION
          }
        end

        private

        def prompt
          <<~PROMPT
            Human: We want to fill in new #{language.name} code between existing code.
            Here is the content of a #{language.name} file in the path '#{file_path_info}' enclosed
            in <existing_code></existing_code> tags. The cursor is currently at the position of the <cursor/> tag.
            Review the existing code to understand existing logic and format.
            Return valid code enclosed in <new_code></new_code> tags which can be inserted at the <cursor> tag.
            If you are not able to write code based on the given instructions return an empty result like <new_code></new_code>.

            Do not repeat code that is already included in <existing_code></existing_code>.
            Here is an example of response which doesn't repeat existing code:

            <examples>
              <example>
                H: <existing_code>
                     def hello_world
                       <cursor>
                     end
                  </existing_code>
                A: puts "Hello, world!"
              </example>
              <example>
                H: <existing_code>
                     def hello_world
                       puts "Hello, <cursor>
                     end
                  </existing_code>
                A: puts "world!"
              </example>
            </examples>

            The new code has to be fully functional and complete. Let's start, here is the existing code:

            <existing_code>
              #{prefix}<cursor>#{suffix}
            </existing_code>

            Assistant: <new_code>
          PROMPT
        end
      end
    end
  end
end
