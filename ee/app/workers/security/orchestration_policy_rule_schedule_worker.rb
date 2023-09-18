# frozen_string_literal: true

module Security
  class OrchestrationPolicyRuleScheduleWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always
    # rubocop:disable Scalability/CronWorkerContext
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    feature_category :security_policy_management

    def perform
      Security::OrchestrationPolicyRuleSchedule.with_configuration_and_project_or_namespace.with_owner.with_security_policy_bots.runnable_schedules.find_in_batches do |schedules|
        schedules.each do |schedule|
          with_context(project: schedule.security_orchestration_policy_configuration.project, user: schedule.owner) do
            if schedule.security_orchestration_policy_configuration.project?
              schedule_rules(schedule)
            else
              Security::OrchestrationPolicyRuleScheduleNamespaceWorker.perform_async(schedule.id)
            end
          end
        end
      end
    end

    private

    def schedule_rules(schedule)
      schedule.schedule_next_run!

      project = schedule.security_orchestration_policy_configuration.project
      return if project.marked_for_deletion?

      user = project.security_policy_bot
      return unless user

      service_result = Security::SecurityOrchestrationPolicies::RuleScheduleService
        .new(project: project, current_user: user)
        .execute(schedule)

      log_message(service_result.errors.join(". "), schedule, user) if service_result.error?
    end

    def log_message(message, schedule, user)
      logger.warn(
        worker: self.class.name,
        security_orchestration_policy_configuration_id: schedule.security_orchestration_policy_configuration_id,
        user_id: user.id,
        message: message
      )
    end
  end
end
