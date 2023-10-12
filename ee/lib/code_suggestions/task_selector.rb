# frozen_string_literal: true

module CodeSuggestions
  class TaskSelector
    # Regex is looking for something that looks like a _single line_ code comment.
    # It looks for GitLab Duo Generate and at least 10 characters
    # afterwards.
    # It is case-insensitive.
    # It searches for the last instance of a match by looking for the end
    # of a text block and an optional line break.
    ALWAYS_GENERATE_PREFIX = %r{.*?}

    INTENT_COMPLETION = 'completion'
    INTENT_GENERATION = 'generation'

    GENERATE_COMMENT_PREFIX = "GitLab Duo Generate:"

    FIRST_COMMENT_REGEX = "(?<comment>%{comment_format})[ \\t]?%{generate_prefix}[ \\t]*(?<instruction>[^\\r\\n]{10,})\\s*\\Z" # rubocop:disable Layout/LineLength

    # TODO: Remove `skip_generate_comment_prefix` when `code_suggestions_no_comment_prefix` feature flag
    # is removed https://gitlab.com/gitlab-org/gitlab/-/issues/424879
    def self.task(params:, unsafe_passthrough_params: {})
      prefix = params.dig(:current_file, :content_above_cursor)
      language = CodeSuggestions::ProgrammingLanguage.detect_from_filename(params.dig(:current_file, :file_name))
      prefix_regex = first_comment_regex(language, params[:intent], params[:skip_generate_comment_prefix])

      result = CodeSuggestions::InstructionsExtractor.extract(language, prefix, prefix_regex)
      intent = params[:intent] || (result.empty? ? INTENT_COMPLETION : INTENT_GENERATION)

      if intent == INTENT_COMPLETION
        model_family = CodeSuggestions::AiModels.code_completion_model_family(
          default: params[:code_completion_model_family],
          split_by_language: params[:code_completion_model_family_split_by_language],
          language: language
        )
        return CodeSuggestions::Tasks::CodeCompletion.new(
          params: params.merge(code_completion_model_family: model_family),
          unsafe_passthrough_params: unsafe_passthrough_params
        )
      end

      model_family = CodeSuggestions::AiModels.code_generation_model_family(
        default: params[:code_generation_model_family],
        split_by_language: params[:code_generation_model_family_split_by_language],
        language: language
      )
      CodeSuggestions::Tasks::CodeGeneration::FromComment.new(
        params: params.merge(
          prefix: result[:prefix]&.chomp! || prefix,
          instruction: result[:instruction],
          code_generation_model_family: model_family
        ),
        unsafe_passthrough_params: unsafe_passthrough_params
      )
    end

    def self.first_comment_regex(language, intent, skip_generate_comment_prefix)
      return ALWAYS_GENERATE_PREFIX if intent == INTENT_GENERATION

      generate_prefix = GENERATE_COMMENT_PREFIX unless skip_generate_comment_prefix
      comment_format = language.single_line_comment_format
      Regexp.new(
        format(FIRST_COMMENT_REGEX, { comment_format: comment_format, generate_prefix: generate_prefix }),
        'im')
    end
  end
end
