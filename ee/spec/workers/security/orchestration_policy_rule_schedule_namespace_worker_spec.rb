# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::OrchestrationPolicyRuleScheduleNamespaceWorker, feature_category: :security_policy_management do
  describe '#perform' do
    let_it_be(:namespace) { create(:group) }
    let_it_be(:project_1) { create(:project, namespace: namespace) }
    let_it_be(:project_2) { create(:project, namespace: namespace) }
    let_it_be(:security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration, :namespace, namespace: namespace) }
    let_it_be(:schedule) { create(:security_orchestration_policy_rule_schedule, security_orchestration_policy_configuration: security_orchestration_policy_configuration) }

    let(:schedule_id) { schedule.id }
    let(:worker) { described_class.new }

    before do
      allow(Security::OrchestrationConfigurationCreateBotWorker).to receive(:perform_async)
      stub_feature_flags(batched_scan_execution_scheduled_pipelines: false)
    end

    shared_examples 'when schedule is created for security orchestration policy configuration in project' do
      context 'when schedule is created for security orchestration policy configuration in project' do
        before do
          security_orchestration_policy_configuration.update!(project: project_1, namespace: nil)
        end

        it 'does not execute the rule schedule worker' do
          expect(Security::ScanExecutionPolicies::RuleScheduleWorker).not_to receive(rule_scheduler_method)

          worker.perform(schedule_id)
        end
      end
    end

    shared_examples 'when schedule does not exist' do
      context 'when schedule does not exist' do
        let(:schedule_id) { non_existing_record_id }

        it 'does not execute the rule schedule worker' do
          expect(Security::ScanExecutionPolicies::RuleScheduleWorker).not_to receive(rule_scheduler_method)

          worker.perform(schedule_id)
        end
      end
    end

    shared_examples 'when schedule exists' do
      context 'when schedule is created for security orchestration policy configuration in namespace' do
        context 'when next_run_at is in future' do
          before do
            schedule.update_column(:next_run_at, 1.minute.from_now)
          end

          it 'does not execute the rule schedule service' do
            expect(Security::SecurityOrchestrationPolicies::RuleScheduleService).not_to receive(:new)

            worker.perform(schedule_id)
          end
        end
      end

      context 'when next_run_at is in the past' do
        before do
          schedule.update_column(:next_run_at, 1.minute.ago)
        end

        it 'creates async new policy bot user only when it is missing for the project' do
          expect(Security::OrchestrationConfigurationCreateBotWorker).to receive(:perform_async).with(project_1.id, nil)
          expect(Security::OrchestrationConfigurationCreateBotWorker).to receive(:perform_async).with(project_2.id, nil)
          expect { worker.perform(schedule_id) }.not_to change { User.count }
        end

        it 'does not invoke the rule schedule worker when there is no security policy bot' do
          expect(Security::ScanExecutionPolicies::RuleScheduleWorker).not_to receive(rule_scheduler_method)

          worker.perform(schedule_id)
        end

        it 'updates next run at value' do
          worker.perform(schedule_id)

          expect(schedule.reload.next_run_at).to be_future
        end

        it 'does not trigger N+1 queries', :use_sql_query_cache do
          control = ActiveRecord::QueryRecorder.new { worker.perform(schedule_id) }

          create(:project, namespace: namespace)
          create(:project, namespace: namespace)
          schedule.update_column(:next_run_at, 1.minute.ago)

          expect { worker.perform(schedule_id) }.to issue_same_number_of_queries_as(control)
        end
      end
    end

    context 'when feature flag batched_scan_execution_scheduled_pipelines is disabled' do
      before do
        stub_feature_flags(batched_scan_execution_scheduled_pipelines: false)
      end

      let(:rule_scheduler_method) { :perform_async }

      it_behaves_like 'when schedule does not exist'

      it_behaves_like 'when schedule is created for security orchestration policy configuration in project'

      it_behaves_like 'when schedule exists'

      context 'when there is a security_policy_bot in the project' do
        let_it_be(:security_policy_bot) { create(:user, :security_policy_bot) }

        before_all do
          schedule.update_column(:next_run_at, 1.minute.ago)
          project_1.add_guest(security_policy_bot)
        end

        it 'creates async new policy bot user only when it is missing for the project' do
          expect(Security::OrchestrationConfigurationCreateBotWorker).not_to receive(:perform_async).with(project_1.id, nil)
          expect(Security::OrchestrationConfigurationCreateBotWorker).to receive(:perform_async).with(project_2.id, nil)
          expect { worker.perform(schedule_id) }.not_to change { User.count }
        end

        it 'invokes the rule schedule worker as the bot user only when it is created for the project' do
          expect(Security::ScanExecutionPolicies::RuleScheduleWorker).to receive(:perform_async).with(project_1.id, security_policy_bot.id, schedule.id)
          expect(Security::ScanExecutionPolicies::RuleScheduleWorker).not_to receive(:perform_async).with(project_2.id, anything, schedule.id)

          worker.perform(schedule_id)
        end
      end

      context 'with namespace including project marked for deletion' do
        let_it_be(:security_policy_bot_2) { create(:user, :security_policy_bot) }
        let_it_be(:project_pending_deletion) { create(:project, namespace: namespace, marked_for_deletion_at: Time.zone.now) }

        before_all do
          schedule.update_column(:next_run_at, 1.minute.ago)
          project_pending_deletion.add_guest(security_policy_bot_2)
        end

        it 'does not call RuleScheduleWorker for the project' do
          expect(Security::ScanExecutionPolicies::RuleScheduleWorker).not_to receive(:perform_async).with(project_pending_deletion.id, schedule.owner.id, schedule.id)

          worker.perform(schedule_id)
        end
      end

      context 'when the cadence is not valid' do
        before do
          schedule.update_column(:cron, '*/5 * * * *')
          schedule.update_column(:next_run_at, 1.minute.ago)
        end

        it 'does not execute the rule schedule worker' do
          expect(Security::ScanExecutionPolicies::RuleScheduleWorker).not_to receive(:perform_async)

          worker.perform(schedule_id)
        end

        it 'logs the error' do
          [project_1, project_2].each do |project|
            expect(::Gitlab::AppJsonLogger).to receive(:info).once.with(
              event: 'scheduled_scan_execution_policy_validation',
              message: 'Invalid cadence',
              project_id: project.id,
              cadence: schedule.cron).and_call_original
          end

          worker.perform(schedule_id)
        end
      end
    end

    context 'when feature flag batched_scan_execution_scheduled_pipelines is enabled' do
      before do
        stub_feature_flags(batched_scan_execution_scheduled_pipelines: true)
      end

      let(:rule_scheduler_method) { :bulk_perform_in_with_contexts }

      it_behaves_like 'when schedule does not exist'

      it_behaves_like 'when schedule is created for security orchestration policy configuration in project'

      it_behaves_like 'when schedule exists'

      context 'when next_run_at is in the past' do
        before do
          schedule.update_column(:next_run_at, 1.minute.ago)
        end

        context 'with namespace including project marked for deletion' do
          let_it_be(:security_policy_bot_2) { create(:user, :security_policy_bot) }
          let_it_be(:project_pending_deletion) { create(:project, namespace: namespace, marked_for_deletion_at: Time.zone.now) }

          before_all do
            project_pending_deletion.add_guest(security_policy_bot_2)
          end

          it 'does not call RuleScheduleWorker for the project' do
            stub_const('::Security::OrchestrationPolicyRuleSchedule::DEFAULT_BATCH_SIZE', 1)

            expect(Security::ScanExecutionPolicies::RuleScheduleWorker).not_to receive(:bulk_perform_in_with_contexts).with(1, [project_pending_deletion.id], arguments_proc: instance_of(Proc), context_proc: instance_of(Proc))

            worker.perform(schedule_id)
          end
        end

        context 'when there is a security_policy_bot in the project' do
          let_it_be(:security_policy_bot) { create(:user, :security_policy_bot) }

          before_all do
            project_1.add_guest(security_policy_bot)
          end

          it 'creates async new policy bot user only when it is missing for the project' do
            expect(Security::OrchestrationConfigurationCreateBotWorker).not_to receive(:perform_async).with(project_1.id, nil)
            expect(Security::OrchestrationConfigurationCreateBotWorker).to receive(:perform_async).with(project_2.id, nil)
            expect { worker.perform(schedule_id) }.not_to change { User.count }
          end

          it 'invokes the rule schedule worker as the bot user only when it is created for the project' do
            expect(Security::ScanExecutionPolicies::RuleScheduleWorker).to receive(:bulk_perform_in_with_contexts).with(1, [project_1], arguments_proc: instance_of(Proc), context_proc: instance_of(Proc))
            expect(Security::ScanExecutionPolicies::RuleScheduleWorker).not_to receive(:bulk_perform_in_with_contexts).with(1.minute, [project_2], arguments_proc: instance_of(Proc), context_proc: instance_of(Proc))

            worker.perform(schedule_id)
          end
        end

        context 'when the schedule does not have the batch settings' do
          before do
            stub_const('::Security::OrchestrationPolicyRuleSchedule::DEFAULT_BATCH_SIZE', 1)
          end

          context 'when there is a security_policy_bot in the project' do
            let_it_be(:security_policy_bot) { create(:user, :security_policy_bot) }
            let_it_be(:security_policy_bot_2) { create(:user, :security_policy_bot) }

            before_all do
              project_1.add_guest(security_policy_bot)
              project_2.add_guest(security_policy_bot_2)
            end

            it 'batch schedule the pipelines using the default values' do
              expect(Security::ScanExecutionPolicies::RuleScheduleWorker).to receive(:bulk_perform_in_with_contexts).with(1, [project_1], arguments_proc: instance_of(Proc), context_proc: instance_of(Proc))
              expect(Security::ScanExecutionPolicies::RuleScheduleWorker).to receive(:bulk_perform_in_with_contexts).with(1.minute, [project_2], arguments_proc: instance_of(Proc), context_proc: instance_of(Proc))

              worker.perform(schedule_id)
            end
          end
        end

        context 'when the schedule have the batch settings' do
          let(:policy) do
            {
              name: 'Scheduled DAST 1',
              description: 'This policy runs DAST every 20 mins',
              enabled: true,
              rules: [{ type: 'schedule', branches: %w[production], cadence: '*/20 * * * *', timezone: 'Europe/Amsterdam' }],
              actions: [
                { scan: 'dast', site_profile: 'Site Profile', scanner_profile: 'Scanner Profile' }
              ],
              configuration: {
                pipeline_optimization: {
                  batch: 1,
                  interval: {
                    unit: 'seconds',
                    value: 120
                  }
                }
              }
            }
          end

          before do
            allow_next_found_instance_of(Security::OrchestrationPolicyRuleSchedule) do |instance|
              allow(instance).to receive(:policy).and_return(policy)
            end
          end

          context 'when there is a security_policy_bot in the project' do
            let_it_be(:security_policy_bot) { create(:user, :security_policy_bot) }
            let_it_be(:security_policy_bot_2) { create(:user, :security_policy_bot) }

            before_all do
              project_1.add_guest(security_policy_bot)
              project_2.add_guest(security_policy_bot_2)
            end

            it 'batch schedule the pipelines using the default values' do
              expect(Security::ScanExecutionPolicies::RuleScheduleWorker).to receive(:bulk_perform_in_with_contexts).with(1, [project_1], arguments_proc: instance_of(Proc), context_proc: instance_of(Proc))
              expect(Security::ScanExecutionPolicies::RuleScheduleWorker).to receive(:bulk_perform_in_with_contexts).with(120, [project_2], arguments_proc: instance_of(Proc), context_proc: instance_of(Proc))

              worker.perform(schedule_id)
            end
          end
        end
      end
    end
  end
end
