# frozen_string_literal: true

module GoogleCloudPlatform
  module ArtifactRegistry
    class GetRepositoryService < ::GoogleCloudPlatform::ArtifactRegistry::BaseProjectService
      private

      def call_client
        ServiceResponse.success(payload: client.repository)
      end
    end
  end
end
