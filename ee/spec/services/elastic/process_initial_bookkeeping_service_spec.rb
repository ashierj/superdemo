# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::ProcessInitialBookkeepingService, feature_category: :global_search do
  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue) }

  describe '.backfill_projects!' do
    context 'when project is maintaining indexed associations' do
      before do
        allow(project).to receive(:maintaining_indexed_associations?).and_return(true)
      end

      it 'indexes itself and calls ElasticCommitIndexerWorker and, ElasticWikiIndexerWorker' do
        expect(described_class).to receive(:track!).with(project)
        expect(described_class).to receive(:maintain_indexed_associations).with(project, Elastic::ProcessInitialBookkeepingService::INDEXED_PROJECT_ASSOCIATIONS)
        expect(ElasticCommitIndexerWorker).to receive(:perform_async).with(project.id, false, { force: true })
        expect(ElasticWikiIndexerWorker).to receive(:perform_async).with(project.id, project.class.name, { force: true })

        described_class.backfill_projects!(project)
      end
    end

    it 'raises an exception if non project is provided' do
      expect { described_class.backfill_projects!(issue) }.to raise_error(ArgumentError)
    end

    it 'uses a separate queue' do
      expect { described_class.backfill_projects!(project) }.not_to change { Elastic::ProcessBookkeepingService.queue_size }
    end

    context 'when project is not maintaining indexed associations' do
      before do
        allow(project).to receive(:maintaining_indexed_associations?).and_return(false)
      end

      it 'indexes itself only' do
        expect(described_class).not_to receive(:maintain_indexed_associations)
        expect(ElasticCommitIndexerWorker).not_to receive(:perform_async)
        expect(ElasticWikiIndexerWorker).not_to receive(:perform_async)

        described_class.backfill_projects!(project)
      end
    end
  end
end
