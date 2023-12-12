# frozen_string_literal: true

module Gitlab
  module Llm
    module Templates
      class CategorizeQuestion
        include Gitlab::Utils::StrongMemoize

        PROMPT = ERB.new(<<~PROMPT)
          \n\nHuman: You are helpful assistant, ready to give as accurate answer as possible in JSON format.

          Based on the information below (user input, <% if previous_answer %>previous answer, <% end %>categories, labels, language), classify user input's category, detailed_category, labels. There may be multiple labels. Don't provide clarification or explanation. Always return only a JSON hash, e.g.:
          <example>{"category": "Write, improve, or explain code", "detailed_category": "What are the potential security risks in this code?", "labels": ["contains_credentials", "contains_rejection_previous_answer_incorrect"], "language": "en"}</example>
          <example>{"category": "Documentation about GitLab", "detailed_category": "Documentation about GitLab", "labels": [], "language": "ja"}</example>

          <% if previous_answer %>
          Previous answer:
          <answer><%= previous_answer %></answer>
          <% end %>

          User input:
          <input><%= question %></input>

          Categories:
          <%= ::Gitlab::Llm::Anthropic::Completions::CategorizeQuestion::LLM_MATCHING_CATEGORIES_XML %>

          Labels:
          <%= ::Gitlab::Llm::Anthropic::Completions::CategorizeQuestion::LLM_MATCHING_LABELS_XML %>

          Assistant:
        PROMPT

        def initialize(messages, params = {})
          @messages = messages
          @params = params
        end

        def to_prompt
          previous_message = messages[-2]
          previous_answer = previous_message&.assistant? ? previous_message.content : nil

          PROMPT.result_with_hash(
            question: params[:question],
            previous_answer: previous_answer
          )
        end

        private

        attr_reader :params, :messages
      end
    end
  end
end
