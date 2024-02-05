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

      condition(:relations_for_non_members_available) do
        scope = group_issue? ? subject_container : subject_container.group

        ::Feature.enabled?(:epic_relations_for_non_members, scope)
      end

      condition(:member_or_support_bot) do
        (is_project_member? && can?(:read_issue)) || (support_bot? && service_desk_enabled?)
      end

      rule { can_be_promoted_to_epic }.policy do
        enable :promote_to_epic
      end

      rule do
        summarize_notes_enabled & can?(:read_issue)
      end.enable :summarize_notes

      rule { relations_for_non_members_available & ~member_or_support_bot }.policy do
        prevent :admin_issue_relation
      end
    end
  end
end
