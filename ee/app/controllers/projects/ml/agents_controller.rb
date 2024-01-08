# frozen_string_literal: true

module Projects
  module Ml
    class AgentsController < Projects::ApplicationController
      before_action :authorize_read_agent_registry!
      feature_category :mlops

      MAX_MODELS_PER_PAGE = 20

      def index; end

      def authorize_read_agent_registry!
        render_404 unless can?(current_user, :read_ai_agents, @project)
      end
    end
  end
end
