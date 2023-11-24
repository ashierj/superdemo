# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      class Answer
        attr_accessor :status, :content, :context, :tool, :suggestions, :is_final, :extras
        alias_method :is_final?, :is_final

        def self.from_response(response_body:, tools:, context:)
          parser = Parsers::ChainOfThoughtParser.new(output: response_body)
          parser.parse

          return final_answer(context: context, content: parser.final_answer) if parser.final_answer

          executor = nil
          action = parser.action
          action_input = parser.action_input
          thought = parser.thought
          content = "\nAction: #{action}\nAction Input: #{action_input}\n"

          if tools.present?
            tool = tools.find { |tool_class| tool_class::Executor::NAME == action }
            executor = tool::Executor if tool

            return default_final_answer(context: context) unless tool
          end

          logger.info_or_debug(context.current_user, message: "Answer", content: content)

          new(
            status: :ok,
            context: context,
            content: content,
            tool: executor,
            suggestions: thought,
            is_final: false
          )
        end

        def self.final_answer(context:, content:, extras: nil)
          logger.info_or_debug(context.current_user, message: "Final answer", content: content)

          new(
            status: :ok,
            context: context,
            content: content,
            tool: nil,
            suggestions: nil,
            is_final: true,
            extras: extras
          )
        end

        def self.default_final_answer(context:)
          logger.info_or_debug(context.current_user, message: "Default final answer")

          track_event(context, 'default_answer')

          final_answer(context: context, content: default_final_message)
        end

        def self.default_final_message
          s_("AI|I don't see how I can help. Please give better instructions!")
        end

        def self.error_answer(context:, content:)
          logger.error(message: "Error", error: content)
          track_event(context, 'error_answer')

          new(
            status: :error,
            content: content,
            context: context,
            tool: nil,
            is_final: true
          )
        end

        def initialize(status:, context:, content:, tool:, suggestions: nil, is_final: false, extras: nil)
          @status = status
          @context = context
          @content = content
          @tool = tool
          @suggestions = suggestions
          @is_final = is_final
          @extras = extras
        end

        private_class_method def self.logger
          Gitlab::Llm::Logger.build
        end

        private_class_method def self.track_event(context, action)
          Gitlab::Tracking.event(
            Gitlab::Llm::Chain::Answer.to_s,
            action,
            label: 'gitlab_duo_chat_answer',
            property: context.request_id,
            namespace: context.container,
            user: context.current_user
          )
        end
      end
    end
  end
end
