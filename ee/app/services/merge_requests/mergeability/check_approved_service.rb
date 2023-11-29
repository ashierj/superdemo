# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckApprovedService < CheckBaseService
      identifier :not_approved
      description 'Checks whether the merge request is approved'

      def execute
        return inactive unless merge_request.approval_feature_available?

        if merge_request.approved? && !merge_request.approval_state.temporarily_unapproved?
          success
        else
          failure
        end
      end

      def skip?
        params[:skip_approved_check].present?
      end

      def cacheable?
        false
      end
    end
  end
end
