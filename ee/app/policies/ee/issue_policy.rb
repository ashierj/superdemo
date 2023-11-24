# frozen_string_literal: true

module EE
  module IssuePolicy
    extend ActiveSupport::Concern

    prepended do
      with_scope :subject
      condition(:summarize_notes_enabled) do
        ::Gitlab::Llm::FeatureAuthorizer.new(
          container: subject_container,
          current_user: user,
          feature_name: :summarize_notes
        ).allowed?
      end

      rule { can_be_promoted_to_epic }.policy do
        enable :promote_to_epic
      end

      rule do
        summarize_notes_enabled & can?(:read_issue)
      end.enable :summarize_notes
    end
  end
end
