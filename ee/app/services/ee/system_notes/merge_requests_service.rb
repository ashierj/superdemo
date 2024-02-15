# frozen_string_literal: true

module EE
  module SystemNotes
    module MergeRequestsService
      def merge_when_checks_pass(sha)
        body = "enabled an automatic merge when all merge checks for #{sha} pass"

        create_note(NoteSummary.new(noteable, project, author, body, action: 'merge'))
      end

      # Called when approvals are reset
      #
      # Example Note text:
      #
      # "reset approvals from @user3, @user4, and @user5 by pushing to the branch"
      #
      # Returns the created Note object
      def approvals_reset(cause, approvers)
        # Currently limited to `:new_push` for now as other causes will be added later on.
        return unless cause == :new_push
        return if approvers.empty?

        body = "reset approvals from #{approvers.map(&:to_reference).to_sentence} by pushing to the branch"

        create_note(NoteSummary.new(noteable, project, author, body, action: 'approvals_reset'))
      end
    end
  end
end
