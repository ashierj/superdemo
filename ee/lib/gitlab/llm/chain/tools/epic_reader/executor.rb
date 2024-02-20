# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        module EpicReader
          class Executor < EpicIdentifier::Executor
            include Concerns::ReaderTooling

            RESOURCE_NAME = 'epic'
            NAME = 'EpicReader'
            HUMAN_NAME = 'Epic Search'
            DESCRIPTION = 'Useful tool when you need to retrieve information about a specific epic. ' \
                          'In this context, word `epic` means high-level building block in GitLab that encapsulates ' \
                          'high-level plans and discussions. Epic can contain multiple issues. ' \
                          'Action Input for this tool should be the original question or epic identifier.'

            EXAMPLE =
              <<~PROMPT
                Question: Please identify the author of &epic_identifier epic.
                Picked tools: "EpicReader" tool.
                Reason: You have access to the same resources as user who asks a question.
                  The question is about an epic, so you need to use "EpicReader" tool.
                  Based on this information you can present final answer.
              PROMPT

            PROVIDER_PROMPT_CLASSES = {
              ai_gateway: ::Gitlab::Llm::Chain::Tools::EpicReader::Prompts::Anthropic,
              anthropic: ::Gitlab::Llm::Chain::Tools::EpicReader::Prompts::Anthropic,
              vertex_ai: ::Gitlab::Llm::Chain::Tools::EpicReader::Prompts::VertexAi
            }.freeze
          end
        end
      end
    end
  end
end
