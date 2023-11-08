# frozen_string_literal: true

module Llm
  class CompletionWorker
    include ApplicationWorker

    MAX_RUN_TIME = 20.seconds

    idempotent!
    data_consistency :delayed
    feature_category :ai_abstraction_layer
    urgency :low
    deduplicate :until_executed

    class << self
      def serialize_message(message)
        message.to_h.tap do |hash|
          hash['user'] &&= hash['user'].to_gid
          hash['resource'] &&= hash['resource'].to_gid
        end
      end

      def deserialize_message(message_hash, options)
        message_hash['user'] &&= GitlabSchema.parse_gid(message_hash['user']).find
        message_hash['resource'] &&= GitlabSchema.parse_gid(message_hash['resource']).find

        ::Gitlab::Llm::AiMessage.for(action: message_hash['ai_action']).new(options.merge(message_hash))
      end

      def perform_for(message, options = {})
        perform_async(serialize_message(message), options)
      end
    end

    def perform(user_id, resource_id, resource_class = nil, ai_action_name = nil, options = {})
      if user_id.is_a?(Hash)
        new_perform(user_id, resource_id)
      else # temporary old behavior
        compatible_perform(user_id, resource_id, resource_class, ai_action_name, options)
      end
    end

    private

    def compatible_perform(user_id, resource_id, resource_class, ai_action_name, options)
      message_hash = options.merge(
        user: "gid://gitlab/User/#{user_id}",
        resource: "gid://gitlab/#{resource_class.classify}/#{resource_id}",
        ai_action: ai_action_name,
        role: Gitlab::Llm::AiMessage::ROLE_USER
      ).stringify_keys

      new_perform(message_hash, options)
    end

    def new_perform(prompt_message_hash, options = {})
      return unless Feature.enabled?(:ai_global_switch, type: :ops)

      with_tracking(prompt_message_hash['ai_action']) do
        ai_prompt_message = self.class.deserialize_message(prompt_message_hash, options)

        return unless resource_authorized?(ai_prompt_message) # rubocop:disable Cop/AvoidReturnFromBlocks -- return from a method is expected here.

        log_perform(ai_prompt_message)

        options.symbolize_keys!
        options[:extra_resource] = ::Llm::ExtraResourceFinder
          .new(ai_prompt_message.user, options.delete(:referer_url)).execute

        ai_completion = ::Gitlab::Llm::CompletionsFactory.completion!(ai_prompt_message, options)
        logger.debug(message: "Got Completion Service from factory", class_name: ai_completion.class.name)

        ai_completion.execute
      end
    end

    def with_tracking(ai_action)
      start_time = ::Gitlab::Metrics::System.monotonic_time

      response = yield

      update_error_rate(ai_action, response)
      update_duration_metric(ai_action, ::Gitlab::Metrics::System.monotonic_time - start_time)

      response
    rescue StandardError => err
      update_error_rate(ai_action)
      raise err
    end

    def log_perform(ai_prompt_message)
      logger.debug(
        message: "Performing CompletionWorker",
        user_id: ai_prompt_message.user.to_gid,
        resource_id: ai_prompt_message.resource&.to_gid,
        action_name: ai_prompt_message.ai_action,
        request_id: ai_prompt_message.request_id,
        client_subscription_id: ai_prompt_message.client_subscription_id
      )

      track_snowplow_event(ai_prompt_message)
    end

    def resource_authorized?(ai_prompt_message)
      !ai_prompt_message.resource ||
        ai_prompt_message.user.can?("read_#{ai_prompt_message.resource.to_ability_name}", ai_prompt_message.resource)
    end

    def update_error_rate(ai_action_name, response = nil)
      completion = ::Gitlab::Llm::CompletionsFactory::COMPLETIONS[ai_action_name.to_sym]
      return unless completion

      success = response.try(:errors)&.empty?

      Gitlab::Metrics::Sli::ErrorRate[:llm_completion].increment(
        labels: {
          feature_category: completion[:feature_category],
          service_class: completion[:service_class].name
        },
        error: !success
      )
    end

    def update_duration_metric(ai_action_name, duration)
      completion = ::Gitlab::Llm::CompletionsFactory::COMPLETIONS[ai_action_name.to_sym]
      return unless completion

      labels = {
        feature_category: completion[:feature_category],
        service_class: completion[:service_class].name
      }
      Gitlab::Metrics::Sli::Apdex[:llm_completion].increment(
        labels: labels,
        success: duration <= MAX_RUN_TIME
      )
    end

    def logger
      @logger ||= Gitlab::Llm::Logger.build
    end

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
