# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckJiraStatusService < CheckBaseService
      identifier :jira_association_missing
      description 'Checks whether the title or description references a Jira issue.'

      def execute
        return inactive unless merge_request.project.prevent_merge_without_jira_issue?

        if has_jira_issue_keys?
          success
        else
          failure(reason: identifier)
        end
      end

      def skip?
        false
      end

      def cacheable?
        false
      end

      private

      def has_jira_issue_keys?
        Atlassian::JiraIssueKeyExtractor.has_keys?(
          merge_request.title,
          merge_request.description,
          custom_regex: merge_request.project.jira_integration.reference_pattern
        )
      end
    end
  end
end
