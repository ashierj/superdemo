# frozen_string_literal: true

module Security
  class OrchestrationPolicyRuleScheduleNamespaceWorker
    BATCH_SIZE = 50
    include ApplicationWorker

    feature_category :security_policy_management

    data_consistency :sticky

    idempotent!

    def perform(rule_schedule_id)
      schedule = Security::OrchestrationPolicyRuleSchedule.find_by_id(rule_schedule_id)
      return unless schedule

      security_orchestration_policy_configuration = schedule.security_orchestration_policy_configuration
      return if !security_orchestration_policy_configuration.namespace? || security_orchestration_policy_configuration.namespace.blank?
      return if schedule.next_run_at.future?

      schedule.schedule_next_run!

      projects_in_batches(security_orchestration_policy_configuration).each do |projects|
        bots_by_project_id = security_policy_bot_ids_by_project_ids(projects)

        projects.each do |project|
          user_id = bots_by_project_id[project.id]
          next prepare_security_policy_bot_user(project) unless user_id

          with_context(project: project) do
            Security::ScanExecutionPolicies::RuleScheduleWorker.perform_async(project.id, user_id, schedule.id)
          end
        end
      end
    end

    private

    def prepare_security_policy_bot_user(project)
      Security::OrchestrationConfigurationCreateBotWorker.perform_async(project.id, nil)
    end

    def security_policy_bot_ids_by_project_ids(projects)
      User.security_policy_bots_for_projects(projects).select(:id, :source_id).to_h do |bot|
        [bot.source_id, bot.id]
      end
    end

    def projects_in_batches(configuration)
      configuration
        .namespace
        .all_projects.not_aimed_for_deletion
        .select(:id)
        .find_in_batches(batch_size: BATCH_SIZE) # rubocop: disable CodeReuse/ActiveRecord -- A custom batch size is needed because querying too many bot users at once is too expensive
    end
  end
end
