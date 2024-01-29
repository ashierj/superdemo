# frozen_string_literal: true

require 'set' # rubocop:disable Lint/RedundantRequireStatement -- Ruby 3.1 and earlier needs this. Drop this line after Ruby 3.2+ is only supported.

module Tooling
  # Checks passed files for valid Ruby syntax.
  #
  # It does not check for compile time warnings yet. See https://gitlab.com/-/snippets/1929968
  class CheckRubySyntax
    VALID_RUBYFILES = %w[Rakefile Dangerfile Gemfile Guardfile].to_set.freeze

    attr_reader :files

    def initialize(files)
      @files = files
    end

    def ruby_files
      @ruby_files ||=
        @files.select do |file|
          file.end_with?(".rb") || VALID_RUBYFILES.include?(File.basename(file))
        end
    end

    def run
      ruby_files.filter_map do |file|
        check_ruby(file)
      end
    end

    private

    def check_ruby(file)
      RubyVM::InstructionSequence.compile(File.open(file), file)

      nil
    rescue SyntaxError => e
      e
    end
  end
end
