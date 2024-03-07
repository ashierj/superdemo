# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Tools
        module IssueReader
          class Executor < IssueIdentifier::Executor
            include Concerns::ReaderTooling

            RESOURCE_NAME = 'issue'
            NAME = "IssueReader"
            HUMAN_NAME = 'Issue Search'
            DESCRIPTION = 'Gets the content of the current issue (also referenced as this or that) the user sees ' \
                          'or a specific issue identified by an ID or a URL.' \
                          'In this context, word `issue` means core building block in GitLab that enable ' \
                          'collaboration, discussions, planning and tracking of work.' \
                          'Action Input for this tool should be the original question or issue identifier.'

            EXAMPLE =
              <<~PROMPT
                Question: Please identify the author of #123 issue
                Thought: You have access to the same resources as user who asks a question.
                  Question is about the content of an issue, so you need to use "IssueReader" tool to retrieve and read issue.
                  Based on this information you can present final answer about issue.
                Action: IssueReader
                ActionInput: Please identify the author of #123 issue
              PROMPT

            PROVIDER_PROMPT_CLASSES = {
              ai_gateway: ::Gitlab::Llm::Chain::Tools::IssueReader::Prompts::Anthropic,
              anthropic: ::Gitlab::Llm::Chain::Tools::IssueReader::Prompts::Anthropic,
              vertex_ai: ::Gitlab::Llm::Chain::Tools::IssueReader::Prompts::VertexAi
            }.freeze
          end
        end
      end
    end
  end
end
