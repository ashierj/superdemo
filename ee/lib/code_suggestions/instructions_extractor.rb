# frozen_string_literal: true

module CodeSuggestions
  class InstructionsExtractor
    EMPTY_LINES_LIMIT = 1

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

      single_line_comment_format = @language.single_line_comment_format
      lines.reverse_each do |line|
        next trimmed_lines += 1 if trimmed_lines < EMPTY_LINES_LIMIT && comment_block.empty? && line.strip.empty?
        break unless @language.single_line_comment?(line)

        comment_block.unshift(line)
      end

      # Matches the first comment line requirements
      return {} unless comment_block.first&.match(first_line_regex)

      # lines before the last comment block
      prefix = lines[0...-(comment_block.length + trimmed_lines)].join("")

      instruction = comment_block.map { |line| line.gsub!(single_line_comment_format, '').strip }.join("\n")

      # TODO: Remove when `code_suggestions_no_comment_prefix` feature flag
      # is removed https://gitlab.com/gitlab-org/gitlab/-/issues/424879
      instruction.gsub!(/GitLab Duo Generate:\s?/, '')

      {
        prefix: prefix,
        instruction: instruction
      }
    end

    private

    attr_reader :language, :content, :first_line_regex
  end
end
