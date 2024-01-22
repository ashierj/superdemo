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
        render_404 unless Feature.enabled?(:gcp_artifact_registry, @project) &&
          ::Gitlab::Saas.feature_available?(:google_artifact_registry)
      end
    end
  end
end
