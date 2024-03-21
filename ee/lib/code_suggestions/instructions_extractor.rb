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

    def initialize(file_content, intent)
      @file_content = file_content
      @language = file_content.language
      @intent = intent
    end

    def extract
      return if intent == INTENT_COMPLETION

      comment_block = comment(file_content.lines_above_cursor)
      get_instruction(comment_block)
    end

    private

    attr_reader :language, :file_content, :intent

    def comment(lines)
      comment_block = []
      trimmed_lines = 0

      lines.reverse_each do |line|
        next trimmed_lines += 1 if trimmed_lines < EMPTY_LINES_LIMIT && comment_block.empty? && line.strip.empty?
        break unless language.single_line_comment?(line)

        comment_block.unshift(line)
      end

      comment_block
    end

    def get_instruction(comment_block)
      type = if comment_block.first&.match(first_line_regex)
               :comment
             elsif file_content.small?
               :small_file
             elsif language.cursor_inside_empty_function?(
               file_content.content_above_cursor, file_content.content_below_cursor)
               :empty_function
             elsif intent == INTENT_GENERATION
               # on client side intent is currently detected only for comments, so
               # it's safe to assume that when intent is sent, it's because of comment
               :comment
             end

      return unless type

      Instruction.new(trigger_type: type)
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
