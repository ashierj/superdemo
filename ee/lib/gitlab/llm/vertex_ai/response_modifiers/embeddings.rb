# frozen_string_literal: true

module Gitlab
  module Llm
    module VertexAi
      module ResponseModifiers
        class Embeddings < ::Gitlab::Llm::BaseResponseModifier
          def response_body
            @response_body ||= ai_response&.dig(:predictions, 0, :embeddings, :values)
          end

          def errors
            @errors ||= [ai_response&.dig(:error, :message)].compact
          end
        end
      end
    end
  end
end
