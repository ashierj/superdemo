# frozen_string_literal: true

module CodeSuggestions
  class ProgrammingLanguage
    include Gitlab::Utils::StrongMemoize

    # https://cloud.google.com/vertex-ai/docs/generative-ai/code/code-models-overview
    SUPPORTED_LANGUAGES = {
      "C" => %w[c],
      "C++" => %w[cc cpp],
      "C#" => %w[cs],
      "Clojure" => %w[clj cljs cljc],
      "Dart" => %w[dart],
      "Elixir" => %w[ex],
      "Erlang" => %w[erl],
      "Fortran" => %w[f],
      "Go" => %w[go],
      "SQL" => %w[sql],
      "Groovy" => %w[groovy],
      "Haskell" => %w[hs],
      "HTML" => %w[html],
      "Java" => %w[java],
      "JavaScript" => %w[js],
      "Kotlin" => %w[kt kts],
      "Lean" => %w[lean],
      "Objective-C" => %w[m],
      "OCaml" => %w[ml],
      "Perl" => %w[pl],
      "PHP" => %w[php],
      "Python" => %w[py],
      "Ruby" => %w[rb],
      "Rust" => %w[rs],
      "Scala" => %w[scala],
      "Shell" => %w[sh],
      "Solidity" => %w[sol],
      "Swift" => %w[swift],
      "TypeScript" => %w[ts],
      "VBScript" => %w[vb vbs],
      "Verilog" => %w[v]
    }.freeze

    LANGUAGE_COMMENT_FORMATS = {
      %w[C C++ C# Go Dart Java JavaScript Kotlin Objective-C Rust Scala Swift Groovy PHP Solidity TypeScript Verilog] =>
        {
          single: '//'
        },
      %w[Python Ruby Elixir Perl Shell] =>
        {
          single: '#'
        },
      %w[Erlang] =>
        {
          single: '%'
        },
      %w[OCaml] => # does not support single line comments
        {},
      %w[Clojure Lisp Scheme] =>
        {
          single: ';'
        },
      %w[SQL Haskell Lean] =>
        {
          single: '--'
        },
      %w[VBScript] =>
        {
          single: '\'',
          single_regexp: %r{^[ \t]*'|REM}
        },
      %w[Fortran] =>
        {
          single: '!'
        },
      %w[HTML XML] =>
        {
          single: '!--'
        }
    }.freeze

    DEFAULT = ''
    DEFAULT_FORMAT = {
      single_regexp: %r{^[ \t]*//|#|--}
    }.freeze

    def self.detect_from_filename(current_file)
      extension = File.extname(current_file).delete_prefix('.')
      language = SUPPORTED_LANGUAGES.find do |_language, value|
        value.include?(extension)
      end

      new(language&.first || DEFAULT)
    end

    def self.from_language(name)
      new(name)
    end

    attr_reader :name

    def initialize(name)
      @name = name
    end

    def comment_format
      language_format = DEFAULT_FORMAT

      LANGUAGE_COMMENT_FORMATS.find do |languages, lang_format|
        language_format = lang_format if languages.include?(name)
      end

      language_format
    end
    strong_memoize_attr(:comment_format)

    def single_line_comment_format
      comment_format[:single_regexp] || comment_format[:single]
    end

    def single_line_comment?(line)
      return false if single_line_comment_format.nil?

      if single_line_comment_format.is_a?(Regexp)
        line.strip.match?(single_line_comment_format)
      else
        line.strip.starts_with?(single_line_comment_format)
      end
    end
  end
end
