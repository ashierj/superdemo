# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class ProtectedBranchesForcePushService < BaseProjectService
      def execute
        return [] unless ::Feature.enabled?(:scan_result_policies_block_force_push, project)

        applicable_branches
      end

      private

      def applicable_branches
        @applicable_branches ||= PolicyBranchesService.new(project: project).scan_result_branches(rules)
      end

      def rules
        blocking_policies = applicable_active_policies.select do |rule|
          rule.dig(:approval_settings, :prevent_force_pushing)
        end

        blocking_policies.pluck(:rules).flatten # rubocop: disable CodeReuse/ActiveRecord -- TODO: blocking_policies is a Hash
      end

      def applicable_active_policies
        policy_scope_service = ::Security::SecurityOrchestrationPolicies::PolicyScopeService.new(project: project)

        project
          .all_security_orchestration_policy_configurations
          .flat_map(&:active_scan_result_policies)
          .select { |policy| policy_scope_service.policy_applicable?(policy) }
      end
    end
  end
end
