# frozen_string_literal: true

module CodeSuggestions
  class Instruction
    SMALL_FILE_INSTRUCTION = <<~PROMPT
      Create more new code for this file. If the cursor is inside an empty function,
      generate its most likely contents based on the function name and signature.
    PROMPT

    EMPTY_FUNCTION_INSTRUCTION = <<~PROMPT
      Complete the empty function and generate contents based on the function name and signature.
      Do not repeat the code. Only return the method contents.
    PROMPT

    attr_reader :trigger_type, :instruction

    def initialize(trigger_type:)
      @trigger_type = trigger_type
      @instruction = instruction_from_trigger_type(trigger_type)
    end

    private

    def instruction_from_trigger_type(type)
      case type
      when :empty_function
        EMPTY_FUNCTION_INSTRUCTION
      when :small_file
        SMALL_FILE_INSTRUCTION
      when :comment
        ''
      else
        raise ArgumentError, "Unknwown trigger type #{type}"
      end
    end
  end
end
