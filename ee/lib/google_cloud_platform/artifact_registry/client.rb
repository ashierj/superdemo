# frozen_string_literal: true

require 'google/cloud/artifact_registry/v1'

module GoogleCloudPlatform
  module ArtifactRegistry
    class Client < ::GoogleCloudPlatform::BaseClient
      include Gitlab::Utils::StrongMemoize

      DEFAULT_PAGE_SIZE = 10

      # Initialize and build a new ArtifactRegistry client.
      # This will use glgo and a workload identity federation instance to exchange
      # a JWT from GitLab for an access token to be used with the Google Cloud API.
      #
      # +project_integration+ The project integration that contains project id and the identity
      #                       provider resource name.
      # +user+ The User instance.
      # +artifact_registry_location+ The Artifact Registry location string. Example: 'us-east1'.
      # +artifact_registry_repository+ The Artifact Registry repository name as a string. Example: 'repo'.
      #
      # All parameters are required.
      #
      # Possible exceptions:
      #
      # +ArgumentError+ if one or more of the parameters is blank.
      # +RuntimeError+ if this is used outside the Saas instance.
      def initialize(project_integration:, user:, artifact_registry_location:, artifact_registry_repository:)
        super(project_integration: project_integration, user: user)

        if artifact_registry_location.blank? || artifact_registry_repository.blank?
          raise ArgumentError, BLANK_PARAMETERS_ERROR_MESSAGE
        end

        @artifact_registry_location = artifact_registry_location
        @artifact_registry_repository = artifact_registry_repository
      end

      # Get the Artifact Registry repository object and return it.
      #
      # It will call the gRPC version of
      # https://cloud.google.com/artifact-registry/docs/reference/rest/v1/projects.locations.repositories/get.
      #
      # Return an instance of +Google::Cloud::ArtifactRegistry::V1::Repository+.
      #
      # Possible exceptions:
      #
      # +GoogleCloudPlatform::AuthenticationError+ if an error occurs during the
      # authentication.
      # +GoogleCloudPlatform::ApiError+ if an error occurs when interacting with the
      # Google Cloud API.
      def repository
        request = ::Google::Cloud::ArtifactRegistry::V1::GetRepositoryRequest.new(name: repository_full_name)

        handling_errors do
          client.get_repository(request)
        end
      end

      # Get the collection of docker images of the Artifact Registry repository.
      # Make sure that the target Artifact Registry repository format is set to `DOCKER`.
      #
      # It will call the gRPC version of
      # https://cloud.google.com/artifact-registry/docs/reference/rest/v1/projects.locations.repositories.dockerImages/list.
      #
      # +page_size+ The desired page size. Default to 10.
      # +page_token+ The page token returned in a previous request to get the next page.
      # +order_by+ The desired order as a string. Format: "<column> <direction>".
      #            Possible values for column: name, image_size_bytes, upload_time, build_time, update_time, media_type.
      #            Possible values for direction: asc, desc.
      #
      # All parameters are optional.
      #
      # Return an instance of +Google::Cloud::ArtifactRegistry::V1::ListDockerImagesResponse+ that has the following
      # attributes:
      #
      # +docker_images+ an array of +Google::Cloud::ArtifactRegistry::V1::DockerImage+.
      # +next_page_token+ the next page token as a string. Can be empty.
      #
      # Possible exceptions:
      #
      # +GoogleCloudPlatform::AuthenticationError+ if an error occurs during the
      # authentication.
      # +GoogleCloudPlatform::ApiError+ if an error occurs when interacting with the
      # Google Cloud API.
      def docker_images(page_size: nil, page_token: nil, order_by: nil)
        page_size = DEFAULT_PAGE_SIZE if page_size.blank?
        request = ::Google::Cloud::ArtifactRegistry::V1::ListDockerImagesRequest.new(
          parent: repository_full_name,
          page_size: page_size,
          page_token: page_token,
          order_by: order_by
        )
        handling_errors do
          client.list_docker_images(request).response
        end
      end

      # Get a specific docker image given its name.
      #
      # It will call the gRPC version of
      # https://cloud.google.com/artifact-registry/docs/reference/rest/v1/projects.locations.repositories.dockerImages/get
      #
      # +name+ Name of the docker image as returned by the Google Cloud API when using +docker_images+
      #
      # Return an instance of +Google::Cloud::ArtifactRegistry::V1::DockerImage+.
      #
      # Possible exceptions:
      #
      # +GoogleCloudPlatform::AuthenticationError+ if an error occurs during the
      # authentication.
      # +GoogleCloudPlatform::ApiError+ if an error occurs when interacting with the
      # Google Cloud API.
      def docker_image(name:)
        request = ::Google::Cloud::ArtifactRegistry::V1::GetDockerImageRequest.new(name: name)

        handling_errors do
          client.get_docker_image(request)
        end
      end

      private

      def client
        ::Google::Cloud::ArtifactRegistry::V1::ArtifactRegistry::Client.new do |config|
          json_key_io = StringIO.new(::Gitlab::Json.dump(credentials))
          ext_credentials = Google::Auth::ExternalAccount::Credentials.make_creds(
            json_key_io: json_key_io,
            scope: CLOUD_PLATFORM_SCOPE
          )
          config.credentials = ::Google::Cloud::ArtifactRegistry::V1::ArtifactRegistry::Credentials.new(ext_credentials)
        end
      end
      strong_memoize_attr :client

      def repository_full_name
        "projects/#{google_cloud_project_id}/" \
          "locations/#{@artifact_registry_location}/" \
          "repositories/#{@artifact_registry_repository}"
      end
      strong_memoize_attr :repository_full_name
    end
  end
end
