# frozen_string_literal: true

module Security
  class ProcessScanResultPolicyWorker
    include ApplicationWorker

    idempotent!
    deduplicate :until_executed, if_deduplicated: :reschedule_once, including_scheduled: true

    data_consistency :always
    sidekiq_options retry: true
    feature_category :security_policy_management

    def perform(project_id, configuration_id)
      project = Project.find_by_id(project_id)
      configuration = Security::OrchestrationPolicyConfiguration.find_by_id(configuration_id)
      return unless project && configuration

      sync_policies(project, configuration, applicable_active_policies(configuration, project))

      Security::SecurityOrchestrationPolicies::SyncOpenedMergeRequestsService
        .new(project: project, policy_configuration: configuration)
        .execute
    end

    private

    def applicable_active_policies(configuration, project)
      policy_scope_service = Security::SecurityOrchestrationPolicies::PolicyScopeService.new(project: project)

      configuration
        .active_scan_result_policies
        .select { |policy| policy_scope_service.policy_applicable?(policy) }
    end

    def sync_policies(project, configuration, active_scan_result_policies)
      configuration.delete_scan_finding_rules_for_project(project.id)
      configuration.delete_software_license_policies(project)
      configuration.delete_policy_violations(project)

      configuration.delete_scan_result_policy_reads(project)

      active_scan_result_policies.each_with_index do |policy, policy_index|
        Security::SecurityOrchestrationPolicies::ProcessScanResultPolicyService
          .new(project: project, policy_configuration: configuration, policy: policy, policy_index: policy_index)
          .execute
      end
    end
  end
end
