# frozen_string_literal: true

module Ai
  class Agent < ApplicationRecord
    self.table_name = "ai_agents"

    validates :project, presence: true
    validates :name,
      format: Gitlab::Regex.ml_model_name_regex,
      uniqueness: { scope: :project },
      presence: true,
      length: { maximum: 255 }

    belongs_to :project
    has_many :versions, class_name: 'Ai::AgentVersion'
  end
end
