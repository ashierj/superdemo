# frozen_string_literal: true

module CodeSuggestions
  class TaskFactory
    include Gitlab::Utils::StrongMemoize

    VERTEX_AI = :vertex_ai
    ANTHROPIC = :anthropic

    def initialize(current_user, params:, unsafe_passthrough_params: {})
      @current_user = current_user
      @params = params
      @unsafe_passthrough_params = unsafe_passthrough_params

      @prefix = params.dig(:current_file, :content_above_cursor)
      @suffix = params.dig(:current_file, :content_below_cursor)
      @intent = params[:intent]
    end

    def task
      file_content = CodeSuggestions::FileContent.new(language, prefix, suffix)
      instructions = CodeSuggestions::InstructionsExtractor
        .new(file_content, intent).extract

      if instructions.empty?
        return CodeSuggestions::Tasks::CodeCompletion.new(
          params: code_completion_params,
          unsafe_passthrough_params: unsafe_passthrough_params
        )
      end

      CodeSuggestions::Tasks::CodeGeneration.new(
        params: code_generation_params(instructions),
        unsafe_passthrough_params: unsafe_passthrough_params
      )
    end

    private

    attr_reader :current_user, :params, :unsafe_passthrough_params, :prefix, :suffix, :intent

    def language
      CodeSuggestions::ProgrammingLanguage.detect_from_filename(params.dig(:current_file, :file_name))
    end
    strong_memoize_attr(:language)

    def code_completion_params
      params.merge(code_completion_model_family: VERTEX_AI)
    end

    def code_generation_params(instructions)
      params.merge(
        prefix: instructions[:prefix],
        instruction: instructions[:instruction],
        code_generation_model_family: ANTHROPIC
      )
    end
  end
end
