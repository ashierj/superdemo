# frozen_string_literal: true

module Llm
  class CompletionWorker
    include ApplicationWorker

    idempotent!
    data_consistency :delayed
    feature_category :ai_abstraction_layer
    urgency :low
    deduplicate :until_executed

    class << self
      def serialize_message(message)
        message.to_h.tap do |hash|
          hash['user'] &&= hash['user'].to_gid
          hash['context'] = hash['context'].to_h
          hash['context']['resource'] &&= hash['context']['resource'].to_gid
        end
      end

      def deserialize_message(message_hash, options)
        message_hash['user'] &&= GitlabSchema.parse_gid(message_hash['user']).find
        message_hash['context'] = begin
          message_hash['context']['resource'] &&= GitlabSchema.parse_gid(message_hash['context']['resource']).find
          ::Gitlab::Llm::AiMessageContext.new(message_hash['context'])
        end

        ::Gitlab::Llm::AiMessage.for(action: message_hash['ai_action']).new(options.merge(message_hash))
      end

      def perform_for(message, options = {})
        perform_async(serialize_message(message), options)
      end
    end

    def perform(prompt_message_hash, options = {})
      ai_prompt_message = self.class.deserialize_message(prompt_message_hash, options)

      track_snowplow_event(ai_prompt_message)

      Internal::CompletionService.new(ai_prompt_message, options).execute
    end

    private

    def track_snowplow_event(prompt_message)
      Gitlab::Tracking.event(
        self.class.to_s,
        "perform_completion_worker",
        label: prompt_message.ai_action.to_s,
        property: prompt_message.request_id,
        user: prompt_message.user
      )
    end
  end
end
