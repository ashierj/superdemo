# frozen_string_literal: true

module AutoMerge
  class MergeWhenChecksPassService < AutoMerge::MergeWhenPipelineSucceedsService
    extend Gitlab::Utils::Override

    override :overrideable_available_for_checks
    def overrideable_available_for_checks(merge_request)
      if Feature.enabled?(:additional_merge_when_checks_ready, merge_request.project)
        # We override here to ignore the draft, blocking and discussions checks
        true
      else
        super
      end
    end

    private

    def add_system_note(merge_request)
      return unless merge_request.saved_change_to_auto_merge_enabled?

      SystemNoteService.merge_when_checks_pass(
        merge_request,
        project,
        current_user,
        merge_request.merge_params.symbolize_keys[:sha]
      )
    end

    def check_availability(merge_request)
      return false if Feature.disabled?(:merge_when_checks_pass, merge_request.project)
      return false unless merge_request.approval_feature_available?
      return false if merge_request.project.merge_trains_enabled?

      super ||
        !merge_request.approved? ||
        (Feature.enabled?(:additional_merge_when_checks_ready, merge_request.project) &&
         (merge_request.draft? ||
          merge_request.merge_blocked_by_other_mrs? ||
          !merge_request.mergeable_discussions_state?)
        )
    end
  end
end
