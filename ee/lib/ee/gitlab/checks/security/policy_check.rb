# frozen_string_literal: true

module EE
  module Gitlab
    module Checks
      module Security
        module PolicyCheck
          ERROR_MESSAGE = "Force push is blocked by settings overridden by a security policy"
          LOG_MESSAGE = "Checking if scan result policies apply to branch..."

          def validate!
            return unless ::Feature.enabled?(:scan_result_policies_block_force_push, project)
            return unless project.licensed_feature_available?(:security_orchestration_policies)
            return unless force_push?

            logger.log_timed(LOG_MESSAGE) do
              raise ::Gitlab::GitAccess::ForbiddenError, ERROR_MESSAGE if branch_name_affected_by_policy?
            end
          end

          private

          def branch_name_affected_by_policy?
            configurations = project.all_security_orchestration_policy_configurations
            return if configurations.empty?

            active_policies = configurations.flat_map(&:active_scan_result_policies)
            return if active_policies.empty?

            rules = active_policies.pluck(:rules).flatten # rubocop: disable CodeReuse/ActiveRecord
            service = ::Security::SecurityOrchestrationPolicies::PolicyBranchesService.new(project: project)
            affected_branches = service.scan_result_branches(rules)

            branch_name.in?(affected_branches)
          end

          def force_push?
            ::Gitlab::Checks::ForcePush.force_push?(project, oldrev, newrev)
          end
        end
      end
    end
  end
end
