# frozen_string_literal: true

module CodeSuggestions
  class TaskFactory
    include Gitlab::Utils::StrongMemoize

    # Regex is looking for something that looks like a _single line_ code comment.
    # It looks for GitLab Duo Generate and at least 10 characters
    # afterwards.
    # It is case-insensitive.
    # It searches for the last instance of a match by looking for the end
    # of a text block and an optional line break.
    FIRST_COMMENT_REGEX = "(?<comment>%{comment_format})[ \\t]?%{generate_prefix}[ \\t]*(?<instruction>[^\\r\\n]{10,})\\s*\\Z" # rubocop:disable Layout/LineLength
    ALWAYS_GENERATE_PREFIX = %r{.*?}
    GENERATE_COMMENT_PREFIX = "GitLab Duo Generate:"

    INTENT_COMPLETION = 'completion'
    INTENT_GENERATION = 'generation'

    VERTEX_AI = :vertex_ai
    ANTHROPIC = :anthropic

    # We determined this in an experimental way, without any deep measurements.
    # We're going to iterate on this based on how different AI models performing for these languages.
    ANTHROPIC_CODE_COMPLETION_LANGUAGES = %w[Ruby TypeScript].freeze
    ANTHROPIC_CODE_GENERATION_LANGUAGES = %w[Ruby TypeScript].freeze

    def self.first_comment_regex(language, intent, skip_generate_comment_prefix)
      return ALWAYS_GENERATE_PREFIX if intent == INTENT_GENERATION

      generate_prefix = GENERATE_COMMENT_PREFIX unless skip_generate_comment_prefix
      comment_format = language.single_line_comment_format
      Regexp.new(
        format(FIRST_COMMENT_REGEX, { comment_format: comment_format, generate_prefix: generate_prefix }),
        'im'
      )
    end

    def initialize(current_user, params:, unsafe_passthrough_params: {})
      @current_user = current_user
      @params = params
      @unsafe_passthrough_params = unsafe_passthrough_params

      @prefix = params.dig(:current_file, :content_above_cursor)
      @intent = params[:intent]
    end

    def task
      result = extract_intructions

      if code_completion?(result)
        return CodeSuggestions::Tasks::CodeCompletion.new(
          params: code_completion_params,
          unsafe_passthrough_params: unsafe_passthrough_params
        )
      end

      CodeSuggestions::Tasks::CodeGeneration.new(
        params: code_generation_params(result),
        unsafe_passthrough_params: unsafe_passthrough_params
      )
    end

    private

    attr_reader :current_user, :params, :unsafe_passthrough_params, :prefix, :intent

    def language
      CodeSuggestions::ProgrammingLanguage.detect_from_filename(params.dig(:current_file, :file_name))
    end
    strong_memoize_attr(:language)

    def extract_intructions
      return {} if intent == INTENT_COMPLETION

      prefix_regex = self.class.first_comment_regex(language, intent, skip_generate_comment_prefix?)

      CodeSuggestions::InstructionsExtractor.extract(language, prefix, prefix_regex)
    end

    def code_completion?(instructions)
      return intent == INTENT_COMPLETION if intent

      instructions.empty?
    end

    # TODO: Remove `skip_generate_comment_prefix` when `code_suggestions_no_comment_prefix` feature flag
    # is removed https://gitlab.com/gitlab-org/gitlab/-/issues/424879
    def skip_generate_comment_prefix?
      Feature.enabled?(:code_generation_no_comment_prefix, current_user)
    end
    strong_memoize_attr(:skip_generate_comment_prefix?)

    def code_completion_model_family
      if code_completion_split_by_language?
        return ANTHROPIC_CODE_COMPLETION_LANGUAGES.include?(language&.name) ? ANTHROPIC : VERTEX_AI
      end

      Feature.enabled?(:code_completion_anthropic, current_user) ? ANTHROPIC : VERTEX_AI
    end

    def code_generation_model_family
      if code_generation_split_by_language?
        return ANTHROPIC_CODE_GENERATION_LANGUAGES.include?(language&.name) ? ANTHROPIC : VERTEX_AI
      end

      Feature.enabled?(:code_generation_anthropic, current_user) ? ANTHROPIC : VERTEX_AI
    end

    def code_completion_split_by_language?
      Feature.enabled?(:code_completion_split_by_language, current_user)
    end
    strong_memoize_attr(:code_completion_split_by_language?)

    def code_generation_split_by_language?
      Feature.enabled?(:code_generation_split_by_language, current_user)
    end
    strong_memoize_attr(:code_generation_split_by_language?)

    def code_completion_params
      params.merge(code_completion_model_family: code_completion_model_family)
    end

    def code_generation_params(instructions)
      params.merge(
        prefix: instructions[:prefix]&.chomp! || prefix,
        instruction: instructions[:instruction],
        code_generation_model_family: code_generation_model_family
      )
    end
  end
end
