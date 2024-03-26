# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckRequestedChangesService < CheckBaseService
      identifier :requested_changes
      description 'Checks whether the merge request has changes requested'

      def execute
        return inactive unless merge_request.reviewer_requests_changes_feature

        return failure if merge_request.has_changes_requested?

        success
      end

      def skip?
        false
      end

      def cacheable?
        false
      end
    end
  end
end
