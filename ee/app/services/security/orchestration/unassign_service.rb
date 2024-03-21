# frozen_string_literal: true

module Security
  module Orchestration
    class UnassignService < ::BaseContainerService
      def execute(delete_bot: true)
        return error(_('Policy project doesn\'t exist')) unless security_orchestration_policy_configuration

        old_policy_project = security_orchestration_policy_configuration.security_policy_management_project

        remove_bot if delete_bot

        delete_configuration(security_orchestration_policy_configuration, old_policy_project)
      end

      private

      delegate :security_orchestration_policy_configuration, to: :container

      def delete_configuration(configuration, old_policy_project)
        if container.root_ancestor.delete_redundant_policy_projects?
          Security::DeleteOrchestrationConfigurationWorker.perform_async(
            configuration.id, current_user.id, old_policy_project.id)

          return success
        end

        if configuration.delete
          ::Gitlab::Audit::Auditor.audit(
            name: 'policy_project_updated',
            author: current_user,
            scope: container,
            target: old_policy_project,
            message: "Unlinked #{old_policy_project.name} as the security policy project"
          )

          return success
        end

        error(security_orchestration_policy_configuration.errors.full_messages.to_sentence)
      end

      def success
        ServiceResponse.success
      end

      def error(message)
        ServiceResponse.error(message: message)
      end

      def remove_bot
        if container.is_a?(Project)
          Security::OrchestrationConfigurationRemoveBotWorker.perform_async(container.id, current_user.id)
        else
          container.all_project_ids.pluck_primary_key.each do |project_id|
            Security::OrchestrationConfigurationRemoveBotWorker.perform_async(project_id, current_user.id)
          end
        end
      end
    end
  end
end
