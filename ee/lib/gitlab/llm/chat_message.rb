# frozen_string_literal: true

module Gitlab
  module Llm
    class ChatMessage < AiMessage
      RESET_MESSAGE = '/reset'

      def save!
        ChatStorage.new(user).add(
          id: id,
          request_id: request_id,
          timestamp: timestamp,
          role: role,
          content: content,
          errors: errors,
          extras: extras
        )
      end

      def conversation_reset?
        content == RESET_MESSAGE
      end
    end
  end
end
