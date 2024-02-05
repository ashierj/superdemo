# frozen_string_literal: true

module Security
  class RefreshComplianceFrameworkSecurityPoliciesWorker
    include Gitlab::EventStore::Subscriber

    data_consistency :sticky
    deduplicate :until_executing
    idempotent!

    feature_category :security_policy_management

    def handle_event(event)
      project = Project.find_by_id(event.data[:project_id])
      framework = ComplianceManagement::Framework.find_by_id(event.data[:compliance_framework_id])
      return unless project && framework

      policy_configuration_ids = project.all_security_orchestration_policy_configuration_ids
      return unless policy_configuration_ids.any?

      framework.security_orchestration_policy_configurations.id_in(policy_configuration_ids).find_each do |config|
        next unless config.namespace? &&
          Feature.enabled?(:security_policies_policy_scope, config.namespace)

        Security::ProcessScanResultPolicyWorker.perform_async(project.id, config.id)
      end
    end
  end
end
