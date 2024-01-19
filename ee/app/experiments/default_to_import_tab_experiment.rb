# frozen_string_literal: true

class DefaultToImportTabExperiment < ApplicationExperiment
  control
  variant(:candidate)

  exclude -> { context.actor.user_detail.registration_objective != 'move_repository' }

  private

  def control_behavior; end
  def candidate_behavior; end
end
