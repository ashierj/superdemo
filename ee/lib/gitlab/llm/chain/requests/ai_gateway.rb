# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Requests
        class AiGateway < Base
          attr_reader :ai_client

          TEMPERATURE = 0.1
          STOP_WORDS = ["\n\nHuman", "Observation:"].freeze
          DEFAULT_MAX_TOKENS = 2048

          def initialize(user, tracking_context: {})
            @user = user
            @ai_client = ::Gitlab::Llm::AiGateway::Client.new(user, tracking_context: tracking_context)
            @logger = Gitlab::Llm::Logger.build
          end

          def request(prompt)
            ai_client.stream(
              prompt: prompt[:prompt],
              **default_options.merge(prompt.fetch(:options, {}))
            ) do |data|
              yield data if block_given?
            end
          end

          private

          attr_reader :user, :logger

          def default_options
            {
              temperature: TEMPERATURE,
              stop_sequences: STOP_WORDS,
              max_tokens_to_sample: DEFAULT_MAX_TOKENS
            }
          end
        end
      end
    end
  end
end
