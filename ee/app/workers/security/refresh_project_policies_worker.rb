# frozen_string_literal: true

module Security
  class RefreshProjectPoliciesWorker
    include Gitlab::EventStore::Subscriber

    data_consistency :sticky
    sidekiq_options retry: true

    deduplicate :until_executing, including_scheduled: true
    idempotent!

    feature_category :security_policy_management

    DELAY_INTERVAL = 30.seconds.to_i

    def handle_event(event)
      project = Project.find_by_id(event.data[:project_id])
      return unless project

      return unless project.licensed_feature_available?(:security_orchestration_policies)
      return if Feature.enabled?(:skip_refresh_project_policies, project.root_namespace)

      configurations_with_users = project.all_security_orchestration_policy_configurations.select do |configuration|
        configuration.active_scan_result_policies.any? do |policy|
          policy[:actions].any? do |action|
            action[:user_approvers].present? || action[:user_approvers_ids].present?
          end
        end
      end

      configurations_with_users.each_with_index do |configuration, index|
        Security::ProcessScanResultPolicyWorker.perform_in(index * DELAY_INTERVAL, project.id, configuration.id)
      end
    end
  end
end
