# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        class SlashCommandTool < Tool
          extend ::Gitlab::Utils::Override

          private

          attr_reader :command

          override :prompt_options
          def prompt_options
            super.merge(command_options).merge(selected_text_options)
          end

          def selected_text_options
            file = context.current_file || {}
            opts = {
              language_info: '',
              selected_text: file[:selected_text].to_s
            }

            filename = file[:file_name].to_s
            language = ::CodeSuggestions::ProgrammingLanguage.detect_from_filename(filename)
            if language.name.present?
              opts[:language_info] = "The code is written in #{language.name} and stored as #{filename}"
            end

            opts
          end

          def command_options
            return {} unless command

            command.prompt_options
          end
        end
      end
    end
  end
end
