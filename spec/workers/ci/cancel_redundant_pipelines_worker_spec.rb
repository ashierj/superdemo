# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CancelRedundantPipelinesWorker, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }

  let(:prev_pipeline) { create(:ci_pipeline, project: project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }

  describe '#perform' do
    subject(:perform) { described_class.new.perform(pipeline.id) }

    let(:service) { instance_double('Ci::PipelineCreation::CancelRedundantPipelinesService') }

    it 'calls cancel redundant pipeline service' do
      expect(Ci::PipelineCreation::CancelRedundantPipelinesService)
        .to receive(:new)
        .with(pipeline)
        .and_return(service)

      expect(service).to receive(:execute)

      perform
    end

    context 'if pipeline is deleted' do
      subject(:perform) { described_class.new.perform(non_existing_record_id) }

      it 'does not call redundant pipeline service' do
        expect(Ci::PipelineCreation::CancelRedundantPipelinesService)
          .not_to receive(:new)

        perform
      end
    end

    describe 'interacting with previous pending pipelines', :sidekiq_inline do
      before do
        create(:ci_build, :interruptible, :running, pipeline: prev_pipeline)
      end

      it_behaves_like 'an idempotent worker', :sidekiq_inline do
        let(:job_args) { pipeline }

        it 'cancels the previous pending pipeline' do
          perform

          expect(prev_pipeline.builds.pluck(:status)).to contain_exactly('canceled')
        end
      end
    end
  end
end
