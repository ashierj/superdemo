# frozen_string_literal: true

module CodeSuggestions
  class InstructionsExtractor
    EMPTY_LINES_LIMIT = 1
    MIN_LINES_OF_CODE = 5

    def initialize(language, content, first_line_regex)
      @language = language
      @content = content
      @first_line_regex = first_line_regex
    end

    def self.extract(language, content, first_line_regex)
      new(language, content, first_line_regex).extract
    end

    def extract
      lines = content.to_s.lines
      comment_block = []
      trimmed_lines = 0

      lines.reverse_each do |line|
        next trimmed_lines += 1 if trimmed_lines < EMPTY_LINES_LIMIT && comment_block.empty? && line.strip.empty?
        break unless language.single_line_comment?(line)

        comment_block.unshift(line)
      end

      # lines before the last comment block
      prefix_lines = lines[0...-(comment_block.length + trimmed_lines)]
      prefix = prefix_lines.join("")

      instruction = get_instruction(lines, comment_block)

      return {} unless instruction

      {
        prefix: prefix,
        instruction: instruction
      }
    end

    private

    attr_reader :language, :content, :first_line_regex

    def get_instruction(lines, comment_block)
      if comment_block.first&.match(first_line_regex)
        instruction = comment_block
        .map { |line| line.gsub(language.single_line_comment_format, '').strip }
        .join("\n")
        .gsub(/GitLab Duo Generate:\s?/, '')

        return instruction if instruction
      end

      # Instead of iterating through all lines, we abort when reach `MIN_LINES_OF_CODE`
      non_comment_lines = lines.lazy.reject do |line|
        line.blank? || language.single_line_comment?(line)
      end.take(MIN_LINES_OF_CODE) # rubocop:disable CodeReuse/ActiveRecord

      return 'Create more new code for this file.' if non_comment_lines.count < MIN_LINES_OF_CODE

      nil
    end
  end
end
