# frozen_string_literal: true

module Security
  class PersistSecurityPoliciesWorker
    include ApplicationWorker

    data_consistency :sticky
    idempotent!
    deduplicate :until_executed, if_deduplicated: :reschedule_once
    feature_category :security_policy_management

    def perform(configuration_id)
      configuration = Security::OrchestrationPolicyConfiguration.find_by_id(configuration_id) || return

      configuration.invalidate_policy_yaml_cache

      Security::SecurityOrchestrationPolicies::PersistPolicyService.new(configuration,
        configuration.active_scan_result_policies).execute
    end
  end
end
