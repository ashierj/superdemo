# frozen_string_literal: true

module Gitlab
  module Llm
    class ChatMessage < AiMessage
      RESET_MESSAGE = '/reset'
      CLEAN_HISTORY_MESSAGES = %w[/clean /clear].freeze

      def save!
        storage = ChatStorage.new(user, agent_version_id)

        if CLEAN_HISTORY_MESSAGES.include?(content)
          storage.clean!
        else
          storage.add(self)
        end
      end

      def conversation_reset?
        content == RESET_MESSAGE
      end

      def clean_history?
        CLEAN_HISTORY_MESSAGES.include?(content)
      end

      def question?
        user? && !conversation_reset? && !clean_history?
      end

      def chat?
        true
      end
    end
  end
end
