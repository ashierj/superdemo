# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Search::Zoekt::NamespaceIndexerWorker, :zoekt, feature_category: :global_search do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:unindexed_namespace) { create(:namespace) }
  let_it_be(:unindexed_project) { create(:project, namespace: unindexed_namespace) }

  before do
    zoekt_ensure_namespace_indexed!(namespace)
  end

  describe '#perform' do
    context 'for index operation' do
      subject(:perform) { described_class.new.perform(namespace.id, 'index') }

      let_it_be(:projects) { create_list :project, 3, namespace: namespace }
      let(:default_delay) { described_class::INDEXING_DELAY_PER_PROJECT }

      it 'indexes all projects belonging to the namespace' do
        expect(Search::Zoekt).to receive(:index_in).with(0, projects[0].id)
        expect(Search::Zoekt).to receive(:index_in).with(default_delay, projects[1].id)
        expect(Search::Zoekt).to receive(:index_in).with(default_delay * 2, projects[2].id)

        perform
      end

      context 'when zoekt indexing is disabled' do
        before do
          stub_feature_flags(index_code_with_zoekt: false)
        end

        it 'does nothing' do
          expect(::Search::Zoekt).not_to receive(:index_in)

          perform
        end
      end

      context 'when zoekt indexing is not enabled for the namespace' do
        subject(:perform) { described_class.new.perform(unindexed_namespace.id, 'index') }

        it 'does nothing' do
          expect(::Search::Zoekt).not_to receive(:index_in)

          perform
        end
      end
    end

    context 'for delete operation' do
      subject { described_class.new.perform(namespace.id, 'delete', zoekt_node.id) }

      let_it_be(:projects) { create_list :project, 3, namespace: namespace }

      it 'deletes all projects belonging to the namespace' do
        expect(::Search::Zoekt::DeleteProjectWorker).to receive(:bulk_perform_async)
          .with(a_collection_containing_exactly(
            [projects[0].root_namespace.id, projects[0].id, zoekt_node.id],
            [projects[1].root_namespace.id, projects[1].id, zoekt_node.id],
            [projects[2].root_namespace.id, projects[2].id, zoekt_node.id]
          ))

        subject
      end

      context 'when zoekt indexing is disabled' do
        before do
          stub_feature_flags(index_code_with_zoekt: false)
        end

        it 'does nothing' do
          expect(::Search::Zoekt::DeleteProjectWorker).not_to receive(:bulk_perform_async)

          subject
        end
      end

      context 'when zoekt indexing is not enabled for the namespace' do
        before do
          allow(namespace).to receive(:use_zoekt?).and_return(false)
        end

        it 'deletes index files' do
          expect(::Search::Zoekt::DeleteProjectWorker).to receive(:bulk_perform_async)
            .with(a_collection_containing_exactly(
              [projects[0].root_namespace.id, projects[0].id, zoekt_node.id],
              [projects[1].root_namespace.id, projects[1].id, zoekt_node.id],
              [projects[2].root_namespace.id, projects[2].id, zoekt_node.id]
            ))

          subject
        end
      end
    end
  end
end
