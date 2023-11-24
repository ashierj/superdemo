# frozen_string_literal: true

module Gitlab
  module Llm
    class StageCheck
      EXPERIMENTAL_FEATURES = [
        :ai_analyze_ci_job_failure,
        :summarize_notes,
        :summarize_my_mr_code_review,
        :explain_code,
        :generate_description,
        :generate_test_file,
        :summarize_diff,
        :explain_vulnerability,
        :resolve_vulnerability,
        :generate_commit_message,
        :fill_in_merge_request_template,
        :summarize_submitted_review
      ].freeze
      BETA_FEATURES = [:chat].freeze

      class << self
        def available?(container, feature)
          available_on_experimental_stage?(container, feature) ||
            available_on_beta_stage?(container, feature)
        end

        private

        def available_on_experimental_stage?(container, feature)
          return false unless EXPERIMENTAL_FEATURES.include?(feature)

          root_ancestor = container&.root_ancestor
          return false unless root_ancestor&.experiment_features_enabled

          root_ancestor.licensed_feature_available?(:ai_features)
        end

        # There is no beta setting yet.
        # https://gitlab.com/gitlab-org/gitlab/-/issues/409929
        def available_on_beta_stage?(container, feature)
          return false unless BETA_FEATURES.include?(feature)

          root_ancestor = container&.root_ancestor
          return false unless root_ancestor&.experiment_features_enabled

          root_ancestor.licensed_feature_available?(:ai_features)
        end
      end
    end
  end
end
