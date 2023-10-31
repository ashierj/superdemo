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

    # Treating the file as "empty" doesn't necessarily mean the file size is 0 bytes.
    # "Empty" means there is not much code to retrive code completion instructions.
    def quite_small?
      # Instead of iterating through all lines, we abort when reach `MIN_LINES_OF_CODE`
      non_comment_lines = lines_above_cursor.lazy.reject do |line|
        line.blank? || language.single_line_comment?(line)
      end.take(MIN_LINES_OF_CODE) # rubocop:disable CodeReuse/ActiveRecord

      non_comment_lines.count < MIN_LINES_OF_CODE
    end

    def lines_above_cursor
      content_above_cursor.to_s.lines
    end
  end
end
