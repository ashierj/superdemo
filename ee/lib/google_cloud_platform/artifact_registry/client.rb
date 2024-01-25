# frozen_string_literal: true

require 'google/cloud/artifact_registry/v1'

module GoogleCloudPlatform
  module ArtifactRegistry
    class Client < ::GoogleCloudPlatform::BaseClient
      include Gitlab::Utils::StrongMemoize

      DEFAULT_PAGE_SIZE = 10

      GCP_SUBJECT_TOKEN_ERROR_MESSAGE = 'Unable to retrieve Identity Pool subject token'
      GCP_TOKEN_EXCHANGE_ERROR_MESSAGE = 'Token exchange failed'

      AuthenticationError = Class.new(StandardError)
      ApiError = Class.new(StandardError)

      BLANK_PARAMETERS_ERROR_MESSAGE = 'All GCP parameters are required'
      SAAS_ONLY_ERROR_MESSAGE = "This is a saas only feature that can't run here"

      # Initialize and build a new ArtifactRegistry client.
      # This will use glgo and a workload identity federation instance to exchange
      # a JWT from GitLab for an access token to be used with the GCP API.
      #
      # +project+ The Project instance.
      # +user+ The User instance.
      # +gcp_project_id+ The Google project_id as a string. Example: 'my-project'.
      # +gcp_location+ The Google location string. Example: 'us-east1'.
      # +gcp_repository+ The Google Artifact Registry repository name as a string. Example: 'repo'.
      # +gcp_wlif+ The Google workload identity federation string. Similar to a URL but without the
      #            protocol. Example:
      #            '//iam.googleapis.com/projects/555/locations/global/workloadIdentityPools/pool/providers/sandbox'.
      #
      # All parameters are required.
      #
      # Possible exceptions:
      #
      # +ArgumentError+ if one or more of the parameters is blank.
      # +RuntimeError+ if this is used outside the Saas instance.
      def initialize(project:, user:, gcp_project_id:, gcp_location:, gcp_repository:, gcp_wlif:)
        raise SAAS_ONLY_ERROR_MESSAGE unless Gitlab::Saas.feature_available?(:google_artifact_registry)

        super(project: project, user: user)

        if gcp_project_id.blank? || gcp_location.blank? || gcp_repository.blank? || gcp_wlif.blank?
          raise ArgumentError, BLANK_PARAMETERS_ERROR_MESSAGE
        end

        @gcp_project_id = gcp_project_id
        @gcp_location = gcp_location
        @gcp_repository = gcp_repository
        @gcp_wlif = gcp_wlif
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
      # +GoogleCloudPlatform::ArtifactRegistry::Client::AuthenticationError+ if an error occurs during the
      # authentication.
      # +GoogleCloudPlatform::ArtifactRegistry::Client::ApiError+ if an error occurs when interacting with the GCP API.
      def repository
        request = ::Google::Cloud::ArtifactRegistry::V1::GetRepositoryRequest.new(name: repository_full_name)

        handling_errors do
          gcp_client.get_repository(request)
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
      # +GoogleCloudPlatform::ArtifactRegistry::Client::AuthenticationError+ if an error occurs during the
      # authentication.
      # +GoogleCloudPlatform::ArtifactRegistry::Client::ApiError+ if an error occurs when interacting with the GCP API.
      def docker_images(page_size: nil, page_token: nil, order_by: nil)
        page_size = DEFAULT_PAGE_SIZE if page_size.blank?
        request = ::Google::Cloud::ArtifactRegistry::V1::ListDockerImagesRequest.new(
          parent: repository_full_name,
          page_size: page_size,
          page_token: page_token,
          order_by: order_by
        )
        handling_errors do
          gcp_client.list_docker_images(request).response
        end
      end

      # Get a specific docker image given its name.
      #
      # It will call the gRPC version of
      # https://cloud.google.com/artifact-registry/docs/reference/rest/v1/projects.locations.repositories.dockerImages/get
      #
      # +name+ Name of the docker image as returned by the GCP API when using +docker_images+
      #
      # Return an instance of +Google::Cloud::ArtifactRegistry::V1::DockerImage+.
      #
      # Possible exceptions:
      #
      # +GoogleCloudPlatform::ArtifactRegistry::Client::AuthenticationError+ if an error occurs during the
      # authentication.
      # +GoogleCloudPlatform::ArtifactRegistry::Client::ApiError+ if an error occurs when interacting with the GCP API.
      def docker_image(name:)
        request = ::Google::Cloud::ArtifactRegistry::V1::GetDockerImageRequest.new(name: name)

        handling_errors do
          gcp_client.get_docker_image(request)
        end
      end

      private

      def gcp_client
        ::Google::Cloud::ArtifactRegistry::V1::ArtifactRegistry::Client.new do |config|
          json_key_io = StringIO.new(::Gitlab::Json.dump(credentials(wlif: @gcp_wlif)))
          ext_credentials = Google::Auth::ExternalAccount::Credentials.make_creds(
            json_key_io: json_key_io,
            scope: CLOUD_PLATFORM_SCOPE
          )
          config.credentials = ::Google::Cloud::ArtifactRegistry::V1::ArtifactRegistry::Credentials.new(ext_credentials)
        end
      end
      strong_memoize_attr :gcp_client

      def handling_errors
        yield
      rescue RuntimeError => e
        if e.message.include?(GCP_SUBJECT_TOKEN_ERROR_MESSAGE) || e.message.include?(GCP_TOKEN_EXCHANGE_ERROR_MESSAGE)
          raise AuthenticationError, e.message
        end

        raise
      rescue ::Google::Cloud::Error => e
        raise ApiError, e.message
      end

      def repository_full_name
        "projects/#{@gcp_project_id}/locations/#{@gcp_location}/repositories/#{@gcp_repository}"
      end
      strong_memoize_attr :repository_full_name
    end
  end
end
