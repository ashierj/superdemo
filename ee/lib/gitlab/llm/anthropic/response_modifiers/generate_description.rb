# frozen_string_literal: true

module Gitlab
  module Llm
    module Anthropic
      module ResponseModifiers
        class GenerateDescription < Gitlab::Llm::BaseResponseModifier
          def response_body
            ai_response&.dig("completion").to_s.strip
          end

          def errors
            @errors ||= [ai_response&.dig('error', 'message')].compact
          end
        end
      end
    end
  end
end
