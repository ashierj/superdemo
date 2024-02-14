# frozen_string_literal: true

module Types
  module GoogleCloud
    module ArtifactRegistry
      class RepositoryType < BaseObject
        graphql_name 'GoogleCloudArtifactRegistryRepository'
        description 'Represents a repository of Google Cloud Artifact Registry'

        authorize :read_container_image

        field :project_id,
          GraphQL::Types::String,
          null: false,
          description: 'ID of the Google Cloud project.'

        field :repository,
          GraphQL::Types::String,
          null: false,
          description: 'Repository on the Google Cloud Artifact Registry.'

        field :artifact_registry_repository_url,
          GraphQL::Types::String,
          null: false,
          description: 'Google Cloud URL to access the repository.'

        field :artifacts,
          Types::GoogleCloud::ArtifactRegistry::ArtifactType.connection_type,
          null: true,
          description: 'Google Cloud Artifact Registry repository artifacts. ' \
                       'Returns `null` if `gcp_artifact_registry` feature flag is disabled or GitLab.com feature ' \
                       'is unavailable.',
          resolver: ::Resolvers::GoogleCloud::ArtifactRegistry::RepositoryArtifactsResolver,
          connection_extension: Gitlab::Graphql::Extensions::ExternallyPaginatedArrayExtension

        alias_method :project, :object

        def project_id
          integration.artifact_registry_project_id
        end

        def repository
          integration.artifact_registry_repository
        end

        def artifact_registry_repository_url
          "https://console.cloud.google.com/artifacts/docker/#{project_id}/" \
            "#{integration.artifact_registry_location}/#{repository}"
        end

        private

        def integration
          project.google_cloud_platform_artifact_registry_integration
        end
      end
    end
  end
end
