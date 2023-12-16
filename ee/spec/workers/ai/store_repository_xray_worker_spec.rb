# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ai::StoreRepositoryXrayWorker, type: :worker, feature_category: :code_suggestions do
  describe '#perform' do
    let_it_be(:project) { create(:project) }
    let(:pipeline) do
      create(:ee_ci_pipeline, :with_repository_xray_report, ref: 'master', project: project, user: project.creator)
    end

    before do
      allow(::ScanSecurityReportSecretsWorker).to receive(:perform_async).and_return(nil)
    end

    context 'when there is no pipeline with the given ID' do
      subject(:perform) { described_class.new.perform(0) }

      it 'does not raise an error' do
        expect { perform }.not_to raise_error
      end
    end

    context 'when there is a pipeline with the given ID' do
      subject(:perform) { described_class.new.perform(pipeline.id) }

      it 'will call the StoreRepositoryXrayService' do
        expect_next_instance_of(Ai::StoreRepositoryXrayService) do |service|
          expect(service).to receive(:execute).and_return(true)
        end

        expect { perform }.not_to raise_error
      end
    end
  end
end
