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
    # +project_integration+ The project integration that contains project id and the identity
    #                       provider resource name.
    # +user+ The User instance.
    #
    # All parameters are required.
    #
    # Possible exceptions:
    #
    # +ArgumentError+ if one or more of the parameters is blank.
    # +RuntimeError+ if this is used outside the SaaS instance.
    def initialize(project_integration:, user:, params: {})
      raise ArgumentError, BLANK_PARAMETERS_ERROR_MESSAGE if project_integration.blank? || user.blank?
      raise SAAS_ONLY_ERROR_MESSAGE unless Gitlab::Saas.feature_available?(:google_cloud_support)

      @project_integration = project_integration
      @user = user
      @params = params
    end

    private

    attr_reader :project_integration, :user, :params

    delegate :identity_provider_resource_name, to: :project_integration, prefix: :google_cloud

    def credentials
      ::GoogleCloudPlatform.credentials(
        identity_provider_resource_name: google_cloud_identity_provider_resource_name,
        encoded_jwt: encoded_jwt
      )
    end

    def encoded_jwt
      jwt = ::GoogleCloudPlatform::Jwt.new(
        project: project,
        user: user,
        claims: {
          audience: GLGO_BASE_URL,
          target_audience: google_cloud_identity_provider_resource_name
        }
      )
      jwt.encoded
    end

    def google_cloud_project_id
      @project_integration.artifact_registry_project_id
    end

    def project
      @project_integration.project
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
