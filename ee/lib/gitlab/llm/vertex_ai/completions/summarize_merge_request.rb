# frozen_string_literal: true

module Gitlab
  module Llm
    module VertexAi
      module Completions
        class SummarizeMergeRequest < Gitlab::Llm::Completions::Base
          # rubocop:disable CodeReuse/ActiveRecord
          def execute
            mr_diff = merge_request.merge_request_diffs.find_by(id: options[:diff_id])

            return unless mr_diff.present?

            prompt = generate_prompt(merge_request, mr_diff)

            return unless prompt.present?

            response = response_for(user, prompt)
            response_modifier = ::Gitlab::Llm::VertexAi::ResponseModifiers::Predictions.new(response)

            store_response(response_modifier, mr_diff)
          end
          # rubocop:enable CodeReuse/ActiveRecord

          private

          def merge_request
            resource
          end

          def generate_prompt(merge_request, mr_diff)
            ai_prompt_class.new(merge_request, mr_diff).to_prompt
          end

          def response_for(user, prompt)
            ::Gitlab::Llm::VertexAi::Client
              .new(user, tracking_context: tracking_context)
              .text(
                content: prompt,
                parameters: ::Gitlab::Llm::VertexAi::Configuration.payload_parameters(temperature: 0)
              )
          end

          def store_response(response_modifier, mr_diff)
            return if response_modifier.errors.any? || response_modifier.response_body.blank?

            summary = MergeRequest::DiffLlmSummary.new(
              merge_request_diff: mr_diff,
              content: response_modifier.response_body,
              provider: MergeRequest::DiffLlmSummary.providers[:vertex_ai]
            )

            summary.save! if summary.valid?
            summary
          end
        end
      end
    end
  end
end
