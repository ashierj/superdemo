# frozen_string_literal: true

module Ai
  class AgentPresenter < Gitlab::View::Presenter::Delegated
    presents ::Ai::Agent, as: :agent

    def path
      project_ml_agent_path(agent.project, agent.id)
    end
  end
end
