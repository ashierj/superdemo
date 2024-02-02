# frozen_string_literal: true

module GoogleCloudPlatform
  class BaseClient
    CLOUD_PLATFORM_SCOPE = 'https://www.googleapis.com/auth/cloud-platform'

    GCP_SUBJECT_TOKEN_ERROR_MESSAGE = 'Unable to retrieve glgo token'
    GCP_TOKEN_EXCHANGE_ERROR_MESSAGE = 'Token exchange failed'

    SAAS_ONLY_ERROR_MESSAGE = "This is a SaaS-only feature that can't run here"
    BLANK_PARAMETERS_ERROR_MESSAGE = 'All Google Cloud parameters are required'

    # Initialize and build a new Compute client.
    # This will use glgo and a workload identity federation instance to exchange
    # a JWT from GitLab for an access token to be used with the Google Cloud API.
    #
    # +project+ The Project instance.
    # +user+ The User instance.
    # +gcp_project_id+ The Google project_id as a string. Example: 'my-project'.
    # +gcp_wlif+ The Google workload identity federation string. Similar to a URL but without the
    #            protocol. Example:
    #            '//iam.googleapis.com/projects/555/locations/global/workloadIdentityPools/pool/providers/sandbox'.
    #
    # All parameters are required.
    #
    # Possible exceptions:
    #
    # +ArgumentError+ if one or more of the parameters is blank.
    # +RuntimeError+ if this is used outside the SaaS instance.
    def initialize(project:, user:, gcp_project_id:, gcp_wlif:)
      if project.blank? || user.blank? || gcp_project_id.blank? || gcp_wlif.blank?
        raise ArgumentError, BLANK_PARAMETERS_ERROR_MESSAGE
      end

      raise SAAS_ONLY_ERROR_MESSAGE unless Gitlab::Saas.feature_available?(:google_artifact_registry)

      @project = project
      @user = user
      @gcp_project_id = gcp_project_id
      @gcp_wlif = gcp_wlif
    end

    private

    attr_reader :project, :user, :gcp_project_id, :gcp_wlif

    def credentials
      ::GoogleCloudPlatform.credentials(
        audience: gcp_wlif,
        encoded_jwt: encoded_jwt
      )
    end

    def encoded_jwt
      jwt = ::GoogleCloudPlatform::Jwt.new(
        project: project,
        user: user,
        claims: {
          audience: GLGO_BASE_URL,
          wlif: gcp_wlif
        }
      )
      jwt.encoded
    end

    def handling_errors
      yield
    rescue RuntimeError => e
      if e.message.include?(GCP_SUBJECT_TOKEN_ERROR_MESSAGE) || e.message.include?(GCP_TOKEN_EXCHANGE_ERROR_MESSAGE)
        raise ::GoogleCloudPlatform::AuthenticationError, e.message
      end

      raise
    rescue ::Google::Cloud::Error => e
      raise ::GoogleCloudPlatform::ApiError, e.message
    end
  end
end
