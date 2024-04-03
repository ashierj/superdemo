# frozen_string_literal: true

class IssuesMrsEmptyStateExperiment < ApplicationExperiment
  control
  variant(:candidate)

  exclude :signed_out, :empty_project_and_paid_plans

  private

  def control_behavior; end
  def candidate_behavior; end

  def signed_out
    !context.user
  end

  def empty_project_and_paid_plans
    return true unless context.project

    context.project.root_ancestor.paid? && !context.project.root_ancestor.trial?
  end
end
