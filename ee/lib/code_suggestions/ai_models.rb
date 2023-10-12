# frozen_string_literal: true

module CodeSuggestions
  module AiModels
    VERTEX_AI = :vertex_ai
    ANTHROPIC = :anthropic

    # We determined this in an experimental way, without any deep measurements.
    # We're going to iterate on this based on how different AI models performing for these languages.
    ANTHROPIC_CODE_COMPLETION_LANGUAGES = %w[Ruby TypeScript].freeze
    ANTHROPIC_CODE_GENERATION_LANGUAGES = %w[Ruby TypeScript].freeze

    def self.code_completion_model_family(default:, split_by_language:, language:)
      return default unless !!split_by_language

      ANTHROPIC_CODE_COMPLETION_LANGUAGES.include?(language&.name) ? ANTHROPIC : VERTEX_AI
    end

    def self.code_generation_model_family(default:, split_by_language:, language:)
      return default unless !!split_by_language

      ANTHROPIC_CODE_GENERATION_LANGUAGES.include?(language&.name) ? ANTHROPIC : VERTEX_AI
    end
  end
end
