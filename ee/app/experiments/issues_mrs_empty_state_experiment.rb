# frozen_string_literal: true

class IssuesMrsEmptyStateExperiment < ApplicationExperiment
  EXCLUDE_USERS_OLDER_THAN = Date.new(2024, 4, 17)

  control
  variant(:candidate)

  exclude :signed_out_and_old_users, :empty_project_and_paid_plans

  private

  def control_behavior; end
  def candidate_behavior; end

  def signed_out_and_old_users
    return true unless context.user

    context.user.created_at < EXCLUDE_USERS_OLDER_THAN
  end

  def empty_project_and_paid_plans
    return true unless context.project

    context.project.root_ancestor.paid? && !context.project.root_ancestor.trial?
  end
end
