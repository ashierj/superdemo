# frozen_string_literal: true

module Projects
  module Ml
    class AgentsController < Projects::ApplicationController
      before_action :authorize_read_ai_agents!
      before_action :authorize_write_ai_agents!, only: [:new]

      feature_category :mlops

      MAX_MODELS_PER_PAGE = 20

      def index; end

      def new; end

      def show
        @agent_id = params[:agent_id]
      end

      private

      def authorize_read_ai_agents!
        render_404 unless can?(current_user, :read_ai_agents, @project)
      end

      def authorize_write_ai_agents!
        render_404 unless can?(current_user, :write_ai_agents, @project)
      end
    end
  end
end
