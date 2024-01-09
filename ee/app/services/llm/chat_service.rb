# frozen_string_literal: true

module Llm
  class ChatService < BaseService
    private

    def ai_action
      :chat
    end

    def perform
      prompt_message.save!
      GraphqlTriggers.ai_completion_response(prompt_message)
      schedule_completion_worker unless prompt_message.conversation_reset? || prompt_message.clean_history?
    end

    def content(_action_name)
      options[:content]
    end

    def ai_integration_enabled?
      ::Feature.enabled?(:ai_duo_chat_switch, type: :ops)
    end

    def user_can_send_to_ai?
      user.can?(:access_duo_chat)
    end
  end
end
