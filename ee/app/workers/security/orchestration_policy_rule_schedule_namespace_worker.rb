# frozen_string_literal: true

module Security
  class OrchestrationPolicyRuleScheduleNamespaceWorker
    BATCH_SIZE = 50
    include ApplicationWorker
    include Security::SecurityOrchestrationPolicies::CadenceChecker

    feature_category :security_policy_management

    data_consistency :sticky

    idempotent!

    def perform(rule_schedule_id)
      schedule = Security::OrchestrationPolicyRuleSchedule.find_by_id(rule_schedule_id)
      return unless schedule

      security_orchestration_policy_configuration = schedule.security_orchestration_policy_configuration
      return unless should_run?(security_orchestration_policy_configuration, schedule)

      namespace = security_orchestration_policy_configuration.namespace

      unless valid_cadence?(schedule.cron)
        log_invalid_cadence_error(namespace.id, schedule.cron)
        return
      end

      if Feature.enabled?(:batched_scan_execution_scheduled_pipelines, security_orchestration_policy_configuration.namespace)
        return perform_in_batches_with_delay(schedule, security_orchestration_policy_configuration)
      end

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

    def perform_in_batches_with_delay(schedule, security_orchestration_policy_configuration)
      schedule_next_run(schedule)

      bulk_perform(schedule, security_orchestration_policy_configuration)
    end

    private

    def schedule_next_run(schedule)
      schedule.schedule_next_run!
    end

    def bulk_perform(schedule, security_orchestration_policy_configuration)
      delay = schedule.delay
      batch_size = schedule.batch_size

      projects_in_batches(security_orchestration_policy_configuration, batch_size).each_with_index do |projects, index|
        bots_by_project_id = security_policy_bot_ids_by_project_ids(projects)
        projects_with_security_policy_bots, projects_without_security_policy_bots = split_projects_by_security_policy_bot_presence(projects, bots_by_project_id)
        create_missing_security_policy_bots(projects_without_security_policy_bots)

        next unless projects_with_security_policy_bots.present?

        Security::ScanExecutionPolicies::RuleScheduleWorker.bulk_perform_in_with_contexts(
          [1, index * delay].max,
          projects_with_security_policy_bots,
          arguments_proc: ->(project) do
            [project.id,
              bots_by_project_id[project.id],
              schedule.id]
          end,
          context_proc: ->(project) { { project: project } }
        )
      end
    end

    def should_run?(security_orchestration_policy_configuration, schedule)
      namespace_configuration?(security_orchestration_policy_configuration) && schedule_in_the_past?(schedule)
    end

    def namespace_configuration?(security_orchestration_policy_configuration)
      security_orchestration_policy_configuration.namespace? && security_orchestration_policy_configuration.namespace.present?
    end

    def schedule_in_the_past?(schedule)
      schedule.next_run_at.past?
    end

    def split_projects_by_security_policy_bot_presence(projects, bots_by_project_id)
      projects.partition { |project| bots_by_project_id[project.id].present? }
    end

    def create_missing_security_policy_bots(projects)
      projects.each do |project|
        prepare_security_policy_bot_user(project)
      end
    end

    def prepare_security_policy_bot_user(project)
      Security::OrchestrationConfigurationCreateBotWorker.perform_async(project.id, nil)
    end

    def security_policy_bot_ids_by_project_ids(projects)
      User.security_policy_bots_for_projects(projects).select(:id, :source_id).to_h do |bot|
        [bot.source_id, bot.id]
      end
    end

    def projects_in_batches(configuration, batch_size = BATCH_SIZE)
      configuration
        .namespace
        .all_projects
        .not_aimed_for_deletion
        .select(:id)
        .find_in_batches(batch_size: batch_size) # rubocop: disable CodeReuse/ActiveRecord -- A custom batch size is needed because querying too many bot users at once is too expensive
    end

    def log_invalid_cadence_error(namespace_id, cadence)
      Gitlab::AppJsonLogger.info(event: 'scheduled_scan_execution_policy_validation',
        message: 'Invalid cadence',
        namespace_id: namespace_id,
        cadence: cadence)
    end
  end
end
