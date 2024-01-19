# frozen_string_literal: true

module Ai
  class Agent < ApplicationRecord
    include Presentable

    self.table_name = "ai_agents"

    validates :project, presence: true
    validates :name,
      format: Gitlab::Regex.ml_model_name_regex,
      uniqueness: { scope: :project },
      presence: true,
      length: { maximum: 255 }

    belongs_to :project
    has_many :versions, class_name: 'Ai::AgentVersion'

    scope :including_project, -> { includes(:project) }
    scope :for_project, ->(project) { where(project_id: project.id) }
  end
end
