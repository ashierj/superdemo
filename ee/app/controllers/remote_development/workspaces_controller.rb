# frozen_string_literal: true

module RemoteDevelopment
  class WorkspacesController < ApplicationController
    before_action :authorize_remote_development!, only: [:index]
    before_action do
      push_frontend_feature_flag(:remote_development_namespace_agent_authorization, current_user)
    end

    feature_category :remote_development
    urgency :low

    def index; end

    private

    def authorize_remote_development!
      render_404 unless can?(current_user, :access_workspaces_feature)
    end
  end
end
