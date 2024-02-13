# frozen_string_literal: true

module Ai
  class AgentVersion < ApplicationRecord
    self.table_name = "ai_agent_versions"

    include GlobalID::Identification

    validates :project, :agent, presence: true

    validates :prompt,
      length: { maximum: 5000 },
      presence: true

    validates :model,
      length: { maximum: 255 },
      presence: true

    validate :validate_agent

    belongs_to :agent, class_name: 'Ai::Agent'
    belongs_to :project

    private

    def validate_agent
      return unless agent

      errors.add(:agent, 'agent project must be the same') if agent.project_id != project_id
    end
  end
end
