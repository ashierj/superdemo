# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Search::RakeTaskExecutorService, :silence_stdout, feature_category: :global_search do
  let(:logger) { instance_double('Logger') }
  let(:service) { described_class.new(logger: logger) }

  describe '#execute' do
    it 'raises an exception when unknown task is provided' do
      expect { service.execute(:foo) }.to raise_error(ArgumentError)
    end

    it 'raises an exception when the task is not implemented' do
      stub_const('::Search::RakeTaskExecutorService::TASKS', [:foo])

      expect { service.execute(:foo) }.to raise_error(NotImplementedError)
    end

    described_class::TASKS.each do |task|
      it "executes #{task} task" do
        expect(service).to receive(task).and_return(true)

        service.execute(task)
      end
    end
  end

  describe '#index_snippets' do
    subject(:task) { service.execute(:index_snippets) }

    it 'indexes snippets' do
      expect(Snippet).to receive(:es_import)
      expect(logger).to receive(:info).with(/Indexing snippets/).twice

      task
    end
  end

  describe '#pause_indexing' do
    subject(:task) { service.execute(:pause_indexing) }

    let(:settings) { ::Gitlab::CurrentSettings }

    before do
      allow(settings).to receive(:elasticsearch_pause_indexing?).and_return(indexing_paused)
    end

    context 'when indexing is already paused' do
      let(:indexing_paused) { true }

      it 'does not do anything' do
        expect(settings).not_to receive(:update!)
        expect { task }.to output(/Indexing is already paused/).to_stdout
      end
    end

    context 'when indexing is running' do
      let(:indexing_paused) { false }

      it 'pauses indexing' do
        expect(settings).to receive(:update!).with(elasticsearch_pause_indexing: true)
        expect { task }.to output(/Indexing is now paused/).to_stdout
      end
    end
  end

  describe '#resume_indexing' do
    subject(:task) { service.execute(:resume_indexing) }

    let(:settings) { ::Gitlab::CurrentSettings }

    before do
      allow(settings).to receive(:elasticsearch_pause_indexing?).and_return(indexing_paused)
    end

    context 'when indexing is already running' do
      let(:indexing_paused) { false }

      it 'does not do anything' do
        expect(settings).not_to receive(:update!)
        expect { task }.to output(/Indexing is already running/).to_stdout
      end
    end

    context 'when indexing is not running' do
      let(:indexing_paused) { true }

      it 'resumes indexing' do
        expect(settings).to receive(:update!).with(elasticsearch_pause_indexing: false)
        expect { task }.to output(/Indexing is now running/).to_stdout
      end
    end
  end

  describe '#estimate_cluster_size' do
    subject(:task) { service.execute(:estimate_cluster_size) }

    before do
      create(:namespace_root_storage_statistics, repository_size: 1.megabyte)
      create(:namespace_root_storage_statistics, repository_size: 10.megabyte)
      create(:namespace_root_storage_statistics, repository_size: 30.megabyte)
    end

    it 'outputs estimates' do
      expect { task }.to output(/your cluster size should be at least 20.5 MiB/).to_stdout
    end
  end

  describe '#mark_reindex_failed' do
    subject(:task) { service.execute(:mark_reindex_failed) }

    context 'when there is a running reindex job' do
      before do
        Elastic::ReindexingTask.create!
      end

      it 'marks the current reindex job as failed' do
        expect { task }.to change { Elastic::ReindexingTask.running? }.from(true).to(false)
      end

      it 'prints a message after marking it as failed' do
        expect { task }.to output("Marked the current reindexing job as failed.\n").to_stdout
      end
    end

    context 'when no running reindex job' do
      it 'just prints a message' do
        expect { task }.to output("Did not find the current running reindexing job.\n").to_stdout
      end
    end
  end

  describe '#list_pending_migrations' do
    subject(:task) { service.execute(:list_pending_migrations) }

    context 'when there are pending migrations' do
      let(:pending_migrations) { ::Elastic::DataMigrationService.migrations.last(2) }
      let(:pending_migration1) { pending_migrations.first }
      let(:pending_migration2) { pending_migrations.second }

      before do
        allow(::Elastic::DataMigrationService).to receive(:pending_migrations).and_return(pending_migrations)
      end

      it 'outputs pending migrations' do
        expect { task }.to output(/#{pending_migration1.name}\n#{pending_migration2.name}/).to_stdout
      end
    end

    context 'when there is no pending migrations' do
      before do
        allow(::Elastic::DataMigrationService).to receive(:pending_migrations).and_return([])
      end

      it 'outputs message there are no pending migrations' do
        expect { task }.to output(/There are no pending migrations./).to_stdout
      end
    end

    context 'when pending migrations are obsolete' do
      let(:obsolete_pending_migration) { ::Elastic::DataMigrationService.migrations.first }

      before do
        allow(::Elastic::DataMigrationService).to receive(:pending_migrations).and_return([obsolete_pending_migration])
        allow(obsolete_pending_migration).to receive(:obsolete?).and_return(true)
      end

      it 'outputs that the pending migration is obsolete' do
        expect { task }.to output(/#{obsolete_pending_migration.name} \[Obsolete\]/).to_stdout
      end
    end
  end
end
