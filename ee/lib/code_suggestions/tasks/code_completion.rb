# frozen_string_literal: true

module CodeSuggestions
  module Tasks
    class CodeCompletion < Base
      extend ::Gitlab::Utils::Override
      include Gitlab::Utils::StrongMemoize

      override :endpoint_name
      def endpoint_name
        'completions'
      end

      private

      def prompt
        CodeSuggestions::Prompts::CodeCompletion::VertexAi.new(params)
      end
      strong_memoize_attr :prompt
    end
  end
end
