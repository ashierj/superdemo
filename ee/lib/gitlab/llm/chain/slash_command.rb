# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      class SlashCommand
        def self.for(message:, tools: [])
          command, user_input = message.slash_command_and_input
          return unless command

          tool = tools.find do |tool|
            next unless tool::Executor.respond_to?(:slash_commands)

            tool::Executor.slash_commands.has_key?(command)
          end

          return unless tool

          command_options = tool::Executor.slash_commands[command]

          new(name: command, user_input: user_input, tool: tool, command_options: command_options)
        end

        attr_reader :name, :user_input, :tool

        def initialize(name:, user_input:, tool:, command_options:)
          @name = name
          @user_input = user_input
          @tool = tool
          @instruction = command_options[:instruction]
          @instruction_with_input = command_options[:instruction_with_input]
        end

        def prompt_options
          {
            input: instruction
          }
        end

        private

        def instruction
          return @instruction if user_input.blank? || @instruction_with_input.blank?

          format(@instruction_with_input, input: user_input)
        end
      end
    end
  end
end
