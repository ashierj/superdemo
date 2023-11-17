# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Concerns
        module VertexAiPrompt
          CHARACTERS_IN_TOKEN = 4

          # source: https://cloud.google.com/vertex-ai/docs/generative-ai/learn/models
          TOTAL_MODEL_TOKEN_LIMIT = 8192

          # leave a 10% for cases where 1 token does not exactly match to 4 characters
          INPUT_TOKEN_LIMIT = (TOTAL_MODEL_TOKEN_LIMIT * 0.9).to_i.freeze

          # approximate that one token is ~4 characters.
          MAX_CHARACTERS = (INPUT_TOKEN_LIMIT * CHARACTERS_IN_TOKEN).to_i.freeze
        end
      end
    end
  end
end
