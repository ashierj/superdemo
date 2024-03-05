# frozen_string_literal: true

module Projects
  module GoogleCloudPlatform
    class ArtifactRegistryController < ::Projects::ApplicationController
      layout 'project'

      before_action :authorize_read_google_cloud_artifact_registry!
      before_action :ensure_feature!

      feature_category :container_registry

      # The show action renders index to allow frontend routing to work on page refresh
      def show
        render :index
      end

      private

      def ensure_feature!
        render_404 unless project.google_cloud_support_enabled?
      end
    end
  end
end
