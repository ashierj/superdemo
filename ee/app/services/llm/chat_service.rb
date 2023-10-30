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
      schedule_completion_worker unless prompt_message.conversation_reset?
    end

    def content(_action_name)
      options[:content]
    end
  end
end
