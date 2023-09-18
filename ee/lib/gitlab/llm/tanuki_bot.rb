# frozen_string_literal: true

module Gitlab
  module Llm
    class TanukiBot
      include ::Gitlab::Loggable

      REQUEST_TIMEOUT = 30
      CONTENT_ID_FIELD = 'ATTRS'
      CONTENT_ID_REGEX = /CNT-IDX-(?<id>\d+)/
      RECORD_LIMIT = 4
      MODEL = 'claude-instant-1.1'

      def self.enabled_for?(user:)
        return false unless user
        return false unless ::License.feature_available?(:ai_tanuki_bot)
        return false unless Feature.enabled?(:openai_experimentation) && Feature.enabled?(:tanuki_bot, user)
        return false unless ai_feature_enabled?(user)

        true
      end

      def self.ai_feature_enabled?(user)
        return true unless ::Gitlab.com?

        user.any_group_with_ai_available?
      end

      def self.show_breadcrumbs_entry_point_for?(user:)
        return false unless Feature.enabled?(:tanuki_bot_breadcrumbs_entry_point, user)

        enabled_for?(user: user)
      end

      # Note: a Rake task is using this class method to extract embeddings for a test fixture.
      def self.embedding_for_question(openai_client, question)
        embeddings_result = openai_client.embeddings(input: question, moderated: false)

        embeddings_result['data'].first["embedding"]
      end

      # Note: a Rake task is using this class method to extract embeddings for a test fixture.
      def self.get_nearest_neighbors(embedding)
        ::Embedding::TanukiBotMvc.current.neighbor_for(
          embedding,
          limit: RECORD_LIMIT
        ).map do |item|
          item.metadata['source_url'] = item.url

          {
            id: item.id,
            content: item.content,
            metadata: item.metadata
          }
        end
      end

      def initialize(current_user:, question:, logger: nil, tracking_context: {})
        @current_user = current_user
        @question = question
        @logger = logger || Gitlab::Llm::Logger.build
        @correlation_id = Labkit::Correlation::CorrelationId.current_id
        @tracking_context = tracking_context
      end

      def execute
        return empty_response unless question.present?
        return empty_response unless self.class.enabled_for?(user: current_user)

        unless ::Embedding::TanukiBotMvc.any?
          logger.debug(message: "Need to query docs but no embeddings are found")
          return empty_response
        end

        embedding = self.class.embedding_for_question(openai_client, question)
        return empty_response if embedding.nil?

        search_documents = self.class.get_nearest_neighbors(embedding)
        return empty_response if search_documents.empty?

        get_completions(search_documents)
      end

      private

      attr_reader :current_user, :question, :logger, :correlation_id, :tracking_context

      def openai_client
        @openai_client ||= ::Gitlab::Llm::OpenAi::Client.new(
          current_user,
          request_timeout: REQUEST_TIMEOUT,
          tracking_context: tracking_context
        )
      end

      def client
        @client ||= ::Gitlab::Llm::Anthropic::Client.new(current_user, tracking_context: tracking_context)
      end

      def get_completions(search_documents)
        final_prompt = Gitlab::Llm::Anthropic::Templates::TanukiBot
          .final_prompt(question: question, documents: search_documents)

        final_prompt_result = client.complete(
          prompt: final_prompt[:prompt],
          options: {
            model: "claude-instant-1.1"
          }
        )

        unless final_prompt_result.success?
          raise final_prompt_result.dig('error', 'message') || "Final prompt failed with '#{final_prompt_result}'"
        end

        logger.debug(message: "Got Final Result", content: {
          prompt: final_prompt[:prompt],
          status_code: final_prompt_result.code,
          openai_completions_response: final_prompt_result.parsed_response,
          message: 'Final prompt request'
        })

        Gitlab::Llm::Anthropic::ResponseModifiers::TanukiBot.new(final_prompt_result.body)
      end

      def empty_response
        Gitlab::Llm::ResponseModifiers::EmptyResponseModifier.new(
          _("I'm sorry, I was not able to find any documentation to answer your question.")
        )
      end
    end
  end
end
