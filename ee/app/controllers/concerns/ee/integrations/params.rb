# frozen_string_literal: true

module EE
  module Integrations
    module Params
      extend ::Gitlab::Utils::Override

      ALLOWED_PARAMS_EE = [
        :artifact_registry_project_id,
        :artifact_registry_location,
        :artifact_registry_repositories,
        :issues_enabled,
        :multiproject_enabled,
        :pass_unstable,
        :repository_url,
        :static_context,
        :vulnerabilities_enabled,
        :vulnerabilities_issuetype,
        :workload_identity_federation_project_id,
        :workload_identity_federation_project_number,
        :workload_identity_pool_id,
        :workload_identity_pool_project_number,
        :workload_identity_pool_provider_id
      ].freeze

      override :allowed_integration_params
      def allowed_integration_params
        super + ALLOWED_PARAMS_EE
      end
    end
  end
end
