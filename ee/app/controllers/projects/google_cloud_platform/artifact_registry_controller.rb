# frozen_string_literal: true

module Projects
  module GoogleCloudPlatform
    class ArtifactRegistryController < Projects::Registry::ApplicationController
      before_action :ensure_feature!

      feature_category :container_registry

      # The show action renders index to allow frontend routing to work on page refresh
      def show
        render :index
      end

      private

      def ensure_feature!
        render_404 unless project.gcp_artifact_registry_enabled?
      end
    end
  end
end
