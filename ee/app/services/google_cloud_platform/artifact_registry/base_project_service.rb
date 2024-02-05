# frozen_string_literal: true

module GoogleCloudPlatform
  module ArtifactRegistry
    class BaseProjectService < ::BaseProjectService
      ERROR_RESPONSES = {
        saas_only: ServiceResponse.error(message: "This is a SaaS-only feature that can't run here"),
        feature_flag_disabled: ServiceResponse.error(message: 'Feature flag not enabled'),
        access_denied: ServiceResponse.error(message: 'Access denied'),
        no_project_integration: ServiceResponse.error(message: 'Project Artifact Registry integration not set'),
        project_integration_disabled: ServiceResponse.error(message: 'Project Artifact Registry integration not active')
      }.freeze

      GCP_AUTHENTICATION_ERROR_MESSAGE = 'Unable to authenticate against Google Cloud'
      GCP_API_ERROR_MESSAGE = 'Unsuccessful Google Cloud API request'

      def execute
        validation_response = validate_before_execute
        return validation_response if validation_response&.error?

        handling_client_errors { call_client }
      end

      private

      def validate_before_execute
        return ERROR_RESPONSES[:saas_only] unless Gitlab::Saas.feature_available?(:google_artifact_registry)
        return ERROR_RESPONSES[:feature_flag_disabled] unless Feature.enabled?(:gcp_artifact_registry, project)
        return ERROR_RESPONSES[:no_project_integration] unless project_integration.present?
        return ERROR_RESPONSES[:project_integration_disabled] unless project_integration.active

        ERROR_RESPONSES[:access_denied] unless allowed?
      end

      def allowed?
        can?(current_user, :read_container_image, project)
      end

      def client
        ::GoogleCloudPlatform::ArtifactRegistry::Client.new(
          project: project,
          user: current_user,
          gcp_project_id: gcp_project_id,
          gcp_location: gcp_location,
          gcp_repository: gcp_repository,
          gcp_wlif: gcp_wlif
        )
      end

      def gcp_project_id
        project_integration.artifact_registry_project_id
      end

      def gcp_location
        project_integration.artifact_registry_location
      end

      def gcp_repository
        project_integration.artifact_registry_repository
      end

      def gcp_wlif
        project_integration.wlif
      end

      def project_integration
        project.google_cloud_platform_artifact_registry_integration
      end

      def handling_client_errors
        yield
      rescue ::GoogleCloudPlatform::AuthenticationError => e
        log_error_with_project_id(message: e.message)
        ServiceResponse.error(message: GCP_AUTHENTICATION_ERROR_MESSAGE)
      rescue ::GoogleCloudPlatform::ApiError => e
        log_error_with_project_id(message: e.message)
        ServiceResponse.error(message: GCP_API_ERROR_MESSAGE)
      end

      def log_error_with_project_id(message:)
        log_error(class_name: self.class.name, project_id: project&.id, message: message)
      end
    end
  end
end
