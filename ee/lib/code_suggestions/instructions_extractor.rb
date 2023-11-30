# frozen_string_literal: true

module CodeSuggestions
  class InstructionsExtractor
    INTENT_COMPLETION = 'completion'
    INTENT_GENERATION = 'generation'

    # Regex is looking for something that looks like a _single line_ code comment.
    # It looks for at least 10 characters afterwards.
    # It is case-insensitive.
    # It searches for the last instance of a match by looking for the end
    # of a text block and an optional line break.
    FIRST_COMMENT_REGEX = "(?<comment>%{comment_format})[ \\t]*(?<instruction>[^\\r\\n]{10,})\\s*\\Z"
    ALWAYS_GENERATE_PREFIX = %r{.*?}

    EMPTY_LINES_LIMIT = 1

    def initialize(file_content, intent, skip_instruction_extraction)
      @file_content = file_content
      @language = file_content.language
      @intent = intent
      @skip_instruction_extraction = skip_instruction_extraction
    end

    def extract
      return {} if intent == INTENT_COMPLETION

      prefix, comment_block = prefix_and_comment(file_content.lines_above_cursor)
      generation, instruction = get_instruction(comment_block)

      return {} if !generation && intent != INTENT_GENERATION

      {
        prefix: skip_instruction_extraction ? file_content.content_above_cursor : prefix,
        instruction: instruction
      }
    end

    private

    attr_reader :language, :file_content, :intent, :skip_instruction_extraction

    def prefix_and_comment(lines)
      comment_block = []
      trimmed_lines = 0

      lines.reverse_each do |line|
        next trimmed_lines += 1 if trimmed_lines < EMPTY_LINES_LIMIT && comment_block.empty? && line.strip.empty?
        break unless language.single_line_comment?(line)

        comment_block.unshift(line)
      end

      # lines before the last comment block
      comment_lines_count = comment_block.length + trimmed_lines
      prefix_lines = comment_lines_count > 0 ? lines[0...-comment_lines_count] : lines
      prefix = prefix_lines.join('').chomp

      [prefix, comment_block]
    end

    def get_instruction(comment_block)
      if comment_block.first&.match(first_line_regex)
        instruction = comment_block
        .map { |line| line.gsub(language.single_line_comment_format, '').strip }
        .join("\n")
        .gsub(/GitLab Duo Generate:\s?/, '')

        return true, (skip_instruction_extraction ? '' : instruction) if instruction
      end

      if file_content.small?
        return true, <<~PROMPT
          Create more new code for this file. If the cursor is inside an empty function,
          generate its most likely contents based on the function name and signature.
        PROMPT
      end

      if language.cursor_inside_empty_function?(file_content.content_above_cursor, file_content.content_below_cursor)
        return true, <<~PROMPT
          Complete the empty function and generate contents based on the function name and signature.
          Do not repeat the code. Only return the method contents.
        PROMPT
      end

      [false, nil]
    end

    def first_line_regex
      return ALWAYS_GENERATE_PREFIX if intent == INTENT_GENERATION

      comment_format = language.single_line_comment_format
      Regexp.new(
        format(FIRST_COMMENT_REGEX, { comment_format: comment_format }),
        'im'
      )
    end
  end
end
