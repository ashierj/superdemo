# frozen_string_literal: true

module Gitlab
  module Llm
    module Templates
      class CategorizeQuestion
        include Gitlab::Utils::StrongMemoize

        PROMPT = <<~PROMPT
          \n\nHuman: You are helpful assistant, ready to give as accurate answer as possible, in JSON format (i.e. starts with "{" and ends with "}").

          Based on the information below (user input, categories, labels, language, %<previous_answer_prefix>s), classify user input's category, detailed_category, labels. There may be multiple labels. Don't provide clarification or explanation. Always return only a JSON hash, e.g.:
          <example>{"category": "Write, improve, or explain code", "detailed_category": "What are the potential security risks in this code?", "labels": ["contains_credentials", "contains_rejection_previous_answer_incorrect"], "language": "en"}</example>
          <example>{"category": "Documentation about GitLab", "detailed_category": "Documentation about GitLab", "labels": [], "language": "ja"}</example>

          %<previous_answer_section>s

          User input:
          <input>%<question>s</input>

          Categories:
          %<categories>s

          Labels:
          %<labels>s

          Assistant:
        PROMPT

        def initialize(messages, params = {})
          @messages = messages
          @params = params
        end

        def to_prompt
          previous_message = messages[-2]
          previous_answer = previous_message&.assistant? ? previous_message.content : nil

          if previous_answer
            previous_answer_prefix = "previous answer"
            previous_answer_section = "Previous answer:\n<answer>#{previous_answer}</answer>"
          else
            previous_answer_prefix = nil
            previous_answer_section = nil
          end

          format(
            PROMPT,
            question: params[:question],
            previous_answer_prefix: previous_answer_prefix,
            previous_answer_section: previous_answer_section,
            categories: ::Gitlab::Llm::Anthropic::Completions::CategorizeQuestion::LLM_MATCHING_CATEGORIES_XML,
            labels: ::Gitlab::Llm::Anthropic::Completions::CategorizeQuestion::LLM_MATCHING_LABELS_XML
          )
        end

        private

        attr_reader :params, :messages
      end
    end
  end
end
