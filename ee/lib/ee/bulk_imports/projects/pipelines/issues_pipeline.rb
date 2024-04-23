# frozen_string_literal: true

module EE
  module BulkImports
    module Projects
      module Pipelines
        module IssuesPipeline
          include ::BulkImports::EpicObjectCreator

          def load(context, issue)
            return unless issue

            super
            handle_epic_issue(issue) if issue.valid?
          end
        end
      end
    end
  end
end
