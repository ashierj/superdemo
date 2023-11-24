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

      framework.security_orchestration_policy_configurations.find_each do |policy_configuration|
        next unless policy_configuration.namespace? &&
          Feature.enabled?(:security_policies_policy_scope, policy_configuration.namespace)

        Security::ProcessScanResultPolicyWorker.perform_async(project.id, policy_configuration.id)
      end
    end
  end
end
