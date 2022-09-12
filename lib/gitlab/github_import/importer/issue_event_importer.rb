# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class IssueEventImporter
        attr_reader :issue_event, :project, :client

        # issue_event - An instance of `Gitlab::GithubImport::Representation::IssueEvent`.
        # project - An instance of `Project`.
        # client - An instance of `Gitlab::GithubImport::Client`.
        def initialize(issue_event, project, client)
          @issue_event = issue_event
          @project = project
          @client = client
        end

        def execute
          importer = event_importer_class(issue_event)
          if importer
            importer.new(project, client).execute(issue_event)
          else
            Gitlab::GithubImport::Logger.debug(
              message: 'UNSUPPORTED_EVENT_TYPE',
              event_type: issue_event.event, event_github_id: issue_event.id
            )
          end
        end

        private

        def event_importer_class(issue_event)
          case issue_event.event
          when 'closed'
            Gitlab::GithubImport::Importer::Events::Closed
          when 'reopened'
            Gitlab::GithubImport::Importer::Events::Reopened
          when 'labeled', 'unlabeled'
            Gitlab::GithubImport::Importer::Events::ChangedLabel
          when 'renamed'
            Gitlab::GithubImport::Importer::Events::Renamed
          when 'milestoned', 'demilestoned'
            Gitlab::GithubImport::Importer::Events::ChangedMilestone
          when 'cross-referenced'
            Gitlab::GithubImport::Importer::Events::CrossReferenced
          when 'assigned', 'unassigned'
            Gitlab::GithubImport::Importer::Events::ChangedAssignee
          when 'review_requested', 'review_request_removed'
            Gitlab::GithubImport::Importer::Events::ChangedReviewer
          end
        end
      end
    end
  end
end
