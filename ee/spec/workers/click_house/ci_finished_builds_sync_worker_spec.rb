# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::CiFinishedBuildsSyncWorker, :click_house, :freeze_time, feature_category: :runner_fleet do
  let(:worker) { described_class.new }

  let_it_be(:ci_build1) { create(:ci_build, :success) }
  let_it_be(:ci_build2) { create(:ci_build, :pending) }

  subject(:perform) { worker.perform }

  before do
    create_sync_events ci_build1
  end

  include_examples 'an idempotent worker' do
    it 'calls CiFinishedBuildsSyncService and returns its response payload' do
      expect(worker).to receive(:log_extra_metadata_on_done)
        .with(:result, { reached_end_of_table: true, records_inserted: 1 })

      params = { worker_index: 0, total_workers: 1 }
      expect_next_instance_of(::ClickHouse::DataIngestion::CiFinishedBuildsSyncService, params) do |service|
        expect(service).to receive(:execute).and_call_original
      end

      expect(ClickHouse::Client).to receive(:insert_csv).once.and_call_original

      expect { perform }.to change { ci_finished_builds_row_count }.by(::Ci::Build.finished.count)
    end

    context 'when an error is reported from service' do
      before do
        allow(ClickHouse::Client.configuration).to receive(:databases).and_return({})
      end

      it 'skips execution' do
        expect(worker).to receive(:log_extra_metadata_on_done)
          .with(:result, { message: 'ClickHouse database is not configured', reason: :db_not_configured })

        perform
      end
    end
  end

  context 'with 2 workers' do
    subject(:perform) { worker.perform(0, 2) }

    it 'calls CiFinishedBuildsSyncService with correct arguments' do
      expect(worker).to receive(:log_extra_metadata_on_done).once

      params = { worker_index: 0, total_workers: 2 }
      expect_next_instance_of(::ClickHouse::DataIngestion::CiFinishedBuildsSyncService, params) do |service|
        expect(service).to receive(:execute).and_call_original
      end

      expect(ClickHouse::Client).to receive(:insert_csv).once.and_call_original

      perform
    end
  end

  def create_sync_events(*builds)
    builds.each do |build|
      Ci::FinishedBuildChSyncEvent.new(build_id: build.id, build_finished_at: build.finished_at).save!
    end
  end

  def ci_finished_builds_row_count
    ClickHouse::Client.select('SELECT COUNT(*) AS count FROM ci_finished_builds', :main).first['count']
  end
end
