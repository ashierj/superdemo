# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ConcurrencyLimit::ResumeWorker, feature_category: :global_search do
  subject(:worker) { described_class.new }

  let(:worker_with_concurrency_limit) { ElasticCommitIndexerWorker }

  describe '#perform' do
    context 'when there are no jobs in the queue' do
      before do
        allow(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).to receive(:has_jobs_in_queue?)
          .and_return(false)
      end

      it 'does nothing' do
        expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
          .not_to receive(:resume_processing!)

        worker.perform
      end
    end

    context 'when there are jobs in the queue' do
      before do
        allow(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).to receive(:has_jobs_in_queue?)
          .and_return(true)
      end

      it 'resumes processing' do
        expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
         .to receive(:resume_processing!)
         .with(worker_with_concurrency_limit.name, limit: 60)

        worker.perform
      end

      it 'resumes processing if there are other jobs' do
        allow(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersConcurrency).to receive(:workers)
          .and_return(worker_with_concurrency_limit.name => 15)
        expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
         .to receive(:resume_processing!)
         .with(worker_with_concurrency_limit.name, limit: 45)

        worker.perform
      end

      it 'resumes processing if limit is not set' do
        nil_proc = -> { nil }
        expect(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap).to receive(:limit_for).and_return(nil_proc)
        expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
         .to receive(:resume_processing!)
         .with(worker_with_concurrency_limit.name, limit: described_class::DEFAULT_LIMIT)
        expect(described_class).to receive(:perform_in)

        worker.perform
      end
    end
  end
end
