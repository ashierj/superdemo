# frozen_string_literal: true

module Llm
  class BaseService
    INVALID_MESSAGE = 'AI features are not enabled or resource is not permitted to be sent.'

    def initialize(user, resource, options = {})
      @user = user
      @resource = resource
      @options = options
      @logger = Gitlab::Llm::Logger.build
    end

    def execute
      unless valid?
        logger.info(message: "Returning from Service due to validation")
        return error(INVALID_MESSAGE)
      end

      perform
    end

    def valid?
      return false if resource.respond_to?(:resource_parent) && !resource.resource_parent.member?(user)

      ai_integration_enabled? && user_can_send_to_ai?
    end

    private

    attr_reader :user, :resource, :options, :logger

    def perform
      raise NotImplementedError
    end

    def worker_perform(user, resource, action_name, options)
      message = build_message(action_name, user: user)
      options[:request_id] = message.request_id

      message.save! if cache_response?(options)

      if emit_response?(options)
        # We do not add the `client_subscription_id` here on purpose for now.
        # This subscription event happens to sync user messages on multiple open chats.
        # If we'd use the `client_subscription_id`, which is unique to the tab,
        # the other open tabs would not receive the message.
        # https://gitlab.com/gitlab-org/gitlab/-/issues/422773
        GraphqlTriggers.ai_completion_response(
          { user_id: user.to_global_id, resource_id: resource&.to_global_id }, message
        )

        # Once all clients use `chat` for `ai_action` we can remove the trigger above.
        GraphqlTriggers.ai_completion_response({ user_id: user.to_global_id, ai_action: action_name.to_s }, message)
      end

      return success(ai_message: message) if no_worker_message?(message)

      logger.debug(
        message: "Enqueuing CompletionWorker",
        user_id: user.id,
        resource_id: resource&.id,
        resource_class: resource&.class&.name,
        request_id: message.request_id,
        action_name: action_name,
        options: options
      )

      if development_sync_execution?
        ::Llm::CompletionWorker.perform_inline(user.id, resource&.id, resource&.class&.name, action_name, options)
      else
        ::Llm::CompletionWorker.perform_async(user.id, resource&.id, resource&.class&.name, action_name, options)
      end

      success(ai_message: message)
    end

    def ai_integration_enabled?
      Feature.enabled?(:openai_experimentation)
    end

    # https://gitlab.com/gitlab-org/gitlab/-/issues/413520
    def user_can_send_to_ai?
      return true unless ::Gitlab.com?

      user.any_group_with_ai_available?
    end

    def success(payload)
      ServiceResponse.success(payload: payload)
    end

    def error(message)
      ServiceResponse.error(message: message)
    end

    def content(action_name)
      action_name.to_s.humanize
    end

    def no_worker_message?(message)
      message.respond_to?(:conversation_reset?) && message.conversation_reset?
    end

    def cache_response?(options)
      return false if options[:internal_request]

      options.fetch(:cache_response, false)
    end

    def development_sync_execution?
      Gitlab.dev_or_test_env? && Gitlab::Utils.to_boolean(ENV['LLM_DEVELOPMENT_SYNC_EXECUTION'])
    end

    def emit_response?(options)
      return false if options[:internal_request]

      options.fetch(:emit_user_messages, false)
    end

    def build_message(action_name, attributes = {})
      attributes[:request_id] ||= SecureRandom.uuid
      attributes[:content] ||= content(action_name)
      attributes[:role] ||= ::Gitlab::Llm::AiMessage::ROLE_USER

      ::Gitlab::Llm::AiMessage.for(action: action_name).new(attributes)
    end
  end
end
