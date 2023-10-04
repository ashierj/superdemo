# frozen_string_literal: true

module Llm
  class ChatService < BaseService
    private

    def ai_action
      :chat
    end

    def perform
      prompt_message.save!
      emit_prompt_message
      schedule_completion_worker(options.merge(cache_response: true)) unless prompt_message.conversation_reset?
    end

    # We need to broadcast this content over the websocket as well
    # https://gitlab.com/gitlab-org/gitlab/-/issues/413600
    def content(_action_name)
      options[:content]
    end

    def emit_prompt_message
      # We do not add the `client_subscription_id` here on purpose for now.
      # This subscription event happens to sync user messages on multiple open chats.
      # If we'd use the `client_subscription_id`, which is unique to the tab,
      # the other open tabs would not receive the message.
      # https://gitlab.com/gitlab-org/gitlab/-/issues/422773
      GraphqlTriggers.ai_completion_response(
        { user_id: prompt_message.user.to_global_id, resource_id: prompt_message.resource&.to_global_id },
        prompt_message
      )

      # Once all clients use `chat` for `ai_action` we can remove the trigger above.
      GraphqlTriggers.ai_completion_response(
        { user_id: prompt_message.user.to_global_id, ai_action: prompt_message.ai_action.to_s },
        prompt_message
      )
    end
  end
end
