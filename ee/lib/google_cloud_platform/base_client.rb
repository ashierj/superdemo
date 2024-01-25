# frozen_string_literal: true

module GoogleCloudPlatform
  class BaseClient
    GLGO_BASE_URL = if Gitlab.staging?
                      'https://glgo.staging.runway.gitlab.net'
                    else
                      'https://glgo.runway.gitlab.net'
                    end

    GLGO_TOKEN_ENDPOINT_URL = "#{GLGO_BASE_URL}/token".freeze

    CREDENTIALS_TYPE = 'external_account'
    STS_URL = 'https://sts.googleapis.com/v1/token'
    SUBJECT_TOKEN_TYPE = 'urn:ietf:params:oauth:token-type:jwt'
    CREDENTIAL_SOURCE_FORMAT = {
      'type' => 'json',
      'subject_token_field_name' => 'token'
    }.freeze

    CLOUD_PLATFORM_SCOPE = 'https://www.googleapis.com/auth/cloud-platform'

    BLANK_PARAMETERS_ERROR_MESSAGE = 'Project and user parameters are required'

    def self.credentials(audience:, encoded_jwt:)
      {
        type: CREDENTIALS_TYPE,
        audience: audience,
        token_url: STS_URL,
        subject_token_type: SUBJECT_TOKEN_TYPE,
        credential_source: {
          url: GLGO_TOKEN_ENDPOINT_URL,
          headers: { 'Authorization' => "Bearer #{encoded_jwt}" },
          format: CREDENTIAL_SOURCE_FORMAT
        }
      }
    end

    def initialize(project:, user:)
      raise ArgumentError, BLANK_PARAMETERS_ERROR_MESSAGE if project.blank? || user.blank?

      @project = project
      @user = user
    end

    private

    def credentials(wlif:)
      self.class.credentials(
        audience: wlif,
        encoded_jwt: encoded_jwt(wlif: wlif)
      )
    end

    def encoded_jwt(wlif:)
      jwt = ::GoogleCloudPlatform::Jwt.new(
        project: @project,
        user: @user,
        claims: {
          audience: GLGO_BASE_URL,
          wlif: wlif
        }
      )
      jwt.encoded
    end
  end
end
