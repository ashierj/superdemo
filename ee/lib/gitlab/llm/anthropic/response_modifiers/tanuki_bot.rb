# frozen_string_literal: true

module Gitlab
  module Llm
    module Anthropic
      module ResponseModifiers
        class TanukiBot < Gitlab::Llm::BaseResponseModifier
          include Gitlab::Utils::StrongMemoize

          CONTENT_ID_FIELD = 'ATTRS'
          CONTENT_ID_REGEX = /CNT-IDX-(?<id>\d+)/
          NO_ANSWER_REGEX = /i do.*n.+know/i

          def initialize(ai_response, current_user)
            @current_user = current_user
            super(ai_response)
          end

          def response_body
            parsed_response && parsed_response[:content]
          end

          def extras
            return parsed_response[:extras] if parsed_response

            super
          end

          def errors
            @errors ||= [ai_response&.dig(:error)].compact
          end

          private

          attr_reader :current_user

          def parsed_response
            text = ai_response&.dig(:completion).to_s.strip

            return unless text.present?

            message, source_ids = text.split("#{CONTENT_ID_FIELD}:")
            message.strip!

            {
              content: message,
              extras: {
                sources: message.match?(NO_ANSWER_REGEX) ? [] : find_sources(source_ids)
              }
            }
          end
          strong_memoize_attr :parsed_response

          def find_sources(source_ids)
            return [] if source_ids.blank?

            ids = source_ids.match(CONTENT_ID_REGEX).captures.map(&:to_i)
            documents = embeddings_model_class.id_in(ids).select(:url, :metadata)
            documents.map do |doc|
              { source_url: doc.url }.merge(doc.metadata)
            end.uniq
          end

          def embeddings_model_class
            if Feature.enabled?(:use_embeddings_with_vertex, current_user)
              ::Embedding::Vertex::GitlabDocumentation
            else
              ::Embedding::TanukiBotMvc
            end
          end
        end
      end
    end
  end
end
