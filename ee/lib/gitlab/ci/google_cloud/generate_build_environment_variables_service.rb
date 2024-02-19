# frozen_string_literal: true

module Gitlab
  module Ci
    module GoogleCloud
      class GenerateBuildEnvironmentVariablesService
        def initialize(build)
          @build = build

          # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/439200
          @integration = build.project.google_cloud_platform_artifact_registry_integration
        end

        def execute
          return [] unless @integration&.active

          config_json = ::GoogleCloudPlatform.credentials(
            identity_provider_resource_name: @integration.identity_provider_resource_name,
            encoded_jwt: encoded_jwt
          ).to_json
          var_attributes = { value: config_json, public: false, masked: true, file: true }

          [
            { key: 'CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE', **var_attributes },
            { key: 'GOOGLE_APPLICATION_CREDENTIALS', **var_attributes }
          ]
        end

        private

        def encoded_jwt
          JwtV2.for_build(
            @build,
            aud: ::GoogleCloudPlatform::GLGO_BASE_URL,
            target_audience: @integration.identity_provider_resource_name
          )
        end
      end
    end
  end
end
