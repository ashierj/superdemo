# frozen_string_literal: true

module Gitlab
  module Llm
    module Anthropic
      module ResponseModifiers
        class CategorizeQuestion < Gitlab::Llm::BaseResponseModifier
          def errors
            @errors ||= [ai_response&.dig('error')].compact
          end
        end
      end
    end
  end
end
