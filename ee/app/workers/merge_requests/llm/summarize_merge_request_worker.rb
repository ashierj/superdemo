# frozen_string_literal: true

# TODO: This worker is deprecated and will be removed in the future in
# https://gitlab.com/gitlab-org/gitlab/-/issues/423210.
module MergeRequests
  module Llm
    class SummarizeMergeRequestWorker
      include ApplicationWorker

      data_consistency :always
      feature_category :code_review_workflow
      urgency :low
      deduplicate :until_executed

      worker_has_external_dependencies!
      idempotent!

      SUMMARIZE_QUICK_ACTION = 'summarize_quick_action'
      PREPARE_DIFF_SUMMARY = 'prepare_diff_summary'

      def perform(user_id, params = {}); end
    end
  end
end

# Added for JiHu
MergeRequests::Llm::SummarizeMergeRequestWorker.prepend_mod
