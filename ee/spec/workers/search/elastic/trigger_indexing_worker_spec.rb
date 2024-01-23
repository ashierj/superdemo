# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Search::Elastic::TriggerIndexingWorker, feature_category: :global_search do
  let(:job_args) { nil }
  let(:worker) { described_class.new }

  subject(:perform) { worker.perform(*job_args) }

  before do
    stub_ee_application_setting(elasticsearch_indexing: true)
  end

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :delayed

  describe '#perform' do
    context 'when indexing is disabled' do
      before do
        stub_ee_application_setting(elasticsearch_indexing: false)
      end

      it 'returns false' do
        expect(perform).to be false
      end
    end

    context 'when unknown task is provided' do
      let(:job_args) { 'foo' }

      it 'raises ArgumentError' do
        expect { perform }.to raise_error(ArgumentError, 'Unknown task: foo')
      end
    end

    context 'when no task is provided' do
      let(:job_args) { nil }
      let(:tasks_to_schedule) { described_class::TASKS }

      before do
        tasks_to_schedule.each do |task|
          allow(described_class).to receive(:perform_async).with(task, {})
        end
      end

      it 'schedules other tasks' do
        tasks_to_schedule.each do |task|
          expect(described_class).to receive(:perform_async).with(task, {})
        end

        perform
      end
    end

    context 'for task: initiate' do
      context 'when no options provided' do
        let(:job_args) { 'initiate' }
        let(:tasks_to_schedule) { described_class::TASKS }

        it_behaves_like 'an idempotent worker' do
          before do
            tasks_to_schedule.each do |task|
              allow(described_class).to receive(:perform_async).with(task, {})
            end
          end

          it 'schedules other tasks' do
            tasks_to_schedule.each do |task|
              expect(described_class).to receive(:perform_async).with(task, {})
            end

            perform
          end
        end
      end

      context 'when skip option is provided' do
        let(:job_args) { ['initiate', options] }
        let(:options) { { 'skip' => 'projects' } }
        let(:tasks_to_schedule) { described_class::TASKS - [:initiate, :projects] }

        it 'schedules other tasks' do
          tasks_to_schedule.each do |task|
            expect(described_class).to receive(:perform_async).with(task, options)
          end

          perform
        end
      end
    end

    context 'for task: snippets' do
      let(:job_args) { 'snippets' }

      it_behaves_like 'an idempotent worker' do
        before do
          allow(Snippet).to receive(:es_import)
        end

        it 'indexes snippets' do
          expect(Snippet).to receive(:es_import)

          perform
        end
      end
    end

    context 'for task: namespaces' do
      let(:job_args) { 'namespaces' }

      it_behaves_like 'an idempotent worker' do
        it 'indexes namespaces' do
          groups = create_list(:group, 3)
          groups.each do |g|
            allow(g).to receive(:use_elasticsearch?).and_return(true)
          end

          expect(worker).to receive(:namespaces).and_call_original
          expect(ElasticNamespaceIndexerWorker).to receive(:bulk_perform_async_with_contexts)
            .with(groups, { arguments_proc: kind_of(Proc), context_proc: kind_of(Proc) })
          perform
        end
      end

      it 'avoids N+1 queries' do
        create_list(:group, 3)

        worker.perform(*job_args)

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { worker.perform(*job_args) }

        create_list(:group, 5)

        expect { worker.perform(*job_args) }.to issue_same_number_of_queries_as(control)
      end
    end

    context 'for task: projects' do
      let_it_be(:projects) { create_list(:project, 3, :in_group) }

      let(:job_args) { 'projects' }

      before do
        allow(worker).to receive(:projects).and_call_original
        allow(::Elastic::ProcessInitialBookkeepingService).to receive(:backfill_projects!)
      end

      it_behaves_like 'an idempotent worker' do
        it 'indexes projects' do
          projects.each do |p|
            allow(p).to receive(:maintain_elasticsearch?).and_return(true)
          end

          expect(worker).to receive(:projects).and_call_original
          expect(::Elastic::ProcessInitialBookkeepingService).to receive(:backfill_projects!).with(*projects)

          perform
        end
      end

      it 'avoids N+1 queries' do
        worker.perform(*job_args)

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { worker.perform(*job_args) }

        create(:project, :in_group)
        create(:project_namespace, parent: create(:group))
        create(:project)

        expect { worker.perform(*job_args) }.to issue_same_number_of_queries_as(control)
      end
    end

    context 'for task: users' do
      let_it_be(:users) { create_list(:user, 3) }

      let(:job_args) { 'users' }

      it_behaves_like 'an idempotent worker' do
        it 'indexes users' do
          expect(worker).to receive(:users).and_call_original
          expect(::Elastic::ProcessInitialBookkeepingService).to receive(:track!).with(*users)

          perform
        end
      end

      it 'avoids N+1 queries' do
        worker.perform(*job_args)

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { worker.perform(*job_args) }

        create_list(:user, 5)

        expect { worker.perform(*job_args) }.to issue_same_number_of_queries_as(control)
      end
    end
  end
end
