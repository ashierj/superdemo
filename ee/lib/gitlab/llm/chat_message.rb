# frozen_string_literal: true

module Gitlab
  module Llm
    class ChatMessage < AiMessage
      RESET_MESSAGE = '/reset'
      CLEAN_HISTORY_MESSAGE = '/clean'

      def save!
        storage = ChatStorage.new(user)

        case content
        when CLEAN_HISTORY_MESSAGE
          storage.clean!
        else
          storage.add(self)
        end
      end

      def conversation_reset?
        content == RESET_MESSAGE
      end

      def clean_history?
        content == CLEAN_HISTORY_MESSAGE
      end

      def question?
        user? && !conversation_reset? && !clean_history?
      end
    end
  end
end
