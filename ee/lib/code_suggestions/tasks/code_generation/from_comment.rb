# frozen_string_literal: true

module CodeSuggestions
  module Tasks
    module CodeGeneration
      class FromComment < CodeSuggestions::Tasks::Base
        extend ::Gitlab::Utils::Override
        include Gitlab::Utils::StrongMemoize

        override :endpoint_name
        def endpoint_name
          'generations'
        end

        override :body
        def body
          unsafe_passthrough_params.merge(prompt.request_params).to_json
        end

        private

        def prompt
          if params[:code_generation_model_family] == CodeSuggestions::AiModels::ANTHROPIC
            CodeSuggestions::Prompts::CodeGeneration::Anthropic.new(params)
          else
            CodeSuggestions::Prompts::CodeGeneration::VertexAi.new(params)
          end
        end
        strong_memoize_attr :prompt
      end
    end
  end
end
