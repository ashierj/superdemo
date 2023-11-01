# frozen_string_literal: true

module CodeSuggestions
  class FileContent
    MIN_LINES_OF_CODE = 5

    def initialize(language, content_above_cursor, content_below_cursor = '')
      @language = language
      @content_above_cursor = content_above_cursor
      @content_below_cursor = content_below_cursor
    end

    attr_reader :language, :content_above_cursor, :content_below_cursor

    # A content is small then there are no or too few lines of code to retrieve suggestion instructions.
    def small?
      # Instead of iterating through all lines, we abort when reach `MIN_LINES_OF_CODE`
      non_comment_lines = lines_above_cursor.lazy.reject do |line|
        line.blank? || language.single_line_comment?(line)
      end.take(MIN_LINES_OF_CODE) # rubocop:disable CodeReuse/ActiveRecord

      non_comment_lines.count < MIN_LINES_OF_CODE && lines_below_cursor.count < MIN_LINES_OF_CODE
    end

    def lines_above_cursor
      content_above_cursor.to_s.lines
    end

    def lines_below_cursor
      content_below_cursor.to_s.lines
    end
  end
end
