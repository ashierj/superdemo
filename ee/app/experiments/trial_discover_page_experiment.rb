# frozen_string_literal: true

class TrialDiscoverPageExperiment < ApplicationExperiment
  EXCLUDE_USERS_OLDER_THAN = Date.new(2024, 2, 14)

  control
  variant(:candidate)

  exclude :previously_existing_users

  private

  def control_behavior; end
  def candidate_behavior; end

  def previously_existing_users
    actor_created_at = context&.actor&.created_at
    return true if actor_created_at.nil?

    actor_created_at < EXCLUDE_USERS_OLDER_THAN
  end
end
