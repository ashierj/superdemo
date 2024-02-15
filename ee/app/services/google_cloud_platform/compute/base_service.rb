# frozen_string_literal: true

module GoogleCloudPlatform
  module Compute
    class BaseService < ::BaseProjectService
      include BaseServiceUtility

      VALID_ORDER_BY_COLUMNS = %w[creationTimestamp name].freeze
      VALID_ORDER_BY_DIRECTIONS = %w[asc desc].freeze

      MAX_RESULTS_LIMIT = 500

      ERROR_RESPONSES = {
        saas_only: ServiceResponse.error(message: "This is a SaaS-only feature that can't run here"),
        feature_flag_disabled: ServiceResponse.error(message: 'Feature flag not enabled'),
        access_denied: ServiceResponse.error(message: 'Access denied'),
        no_integration: ServiceResponse.error(message: 'Project Artifact Registry integration not set'),
        integration_not_active: ServiceResponse.error(message: 'Project Artifact Registry integration not active'),
        google_cloud_authentication_error:
          ServiceResponse.error(message: 'Unable to authenticate against Google Cloud'),
        invalid_order_by: ServiceResponse.error(message: 'Invalid order_by value'),
        max_results_out_of_bounds: ServiceResponse.error(message: 'Max results argument is out-of-bounds')
      }.freeze

      GCP_API_ERROR_MESSAGE = 'Unsuccessful Google Cloud API request'

      def execute
        params[:max_results] ||= MAX_RESULTS_LIMIT

        validation_response = validate_before_execute
        return validation_response if validation_response&.error?

        handling_client_errors { call_client }
      end

      private

      def validate_before_execute
        return ERROR_RESPONSES[:saas_only] unless Gitlab::Saas.feature_available?(:google_cloud_support)

        unless Feature.enabled?(:google_cloud_runner_provisioning, project)
          return ERROR_RESPONSES[:feature_flag_disabled]
        end

        return ERROR_RESPONSES[:access_denied] unless allowed?

        return ERROR_RESPONSES[:no_integration] unless project_integration
        return ERROR_RESPONSES[:integration_not_active] unless project_integration.active

        return ERROR_RESPONSES[:max_results_out_of_bounds] unless (1..MAX_RESULTS_LIMIT).cover?(max_results)
        return ERROR_RESPONSES[:invalid_order_by] unless valid_order_by?(order_by)

        ServiceResponse.success
      end

      def allowed?
        can?(current_user, :read_runner_cloud_provisioning_options, project)
      end

      def valid_order_by?(value)
        return true if value.blank?

        column, direction = value.split(' ')

        return false unless column.in?(VALID_ORDER_BY_COLUMNS)
        return false unless direction.in?(VALID_ORDER_BY_DIRECTIONS)

        true
      end

      def client
        ::GoogleCloudPlatform::Compute::Client.new(
          project: project,
          user: current_user,
          gcp_project_id: gcp_project_id,
          gcp_wlif: gcp_wlif
        )
      end

      def gcp_project_id
        params[:google_cloud_project_id] || project_integration.artifact_registry_project_id
      end

      def gcp_wlif
        project_integration.wlif
      end

      def project_integration
        project.google_cloud_platform_artifact_registry_integration
      end
      strong_memoize_attr :project_integration

      def max_results
        params[:max_results]
      end

      def filter
        params[:filter]
      end

      def order_by
        params[:order_by]
      end

      def page_token
        params[:page_token]
      end

      def handling_client_errors
        yield
      rescue ::GoogleCloudPlatform::AuthenticationError => e
        log_error_with_project_id(message: e.message)
        ERROR_RESPONSES[:google_cloud_authentication_error]
      rescue ::GoogleCloudPlatform::ApiError => e
        log_error_with_project_id(message: e.message)
        ServiceResponse.error(message: "#{GCP_API_ERROR_MESSAGE}: #{e.message}")
      end

      def log_error_with_project_id(message:)
        log_error(class_name: self.class.name, project_id: project.id, message: message)
      end
    end
  end
end
