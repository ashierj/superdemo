# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Search::Zoekt::DeleteProjectWorker, feature_category: :global_search do
  let_it_be(:zoekt_indexed_namespace) { create(:zoekt_indexed_namespace) }
  let_it_be(:zoekt_node) { zoekt_indexed_namespace.node }

  let(:root_namespace_id) { zoekt_indexed_namespace.namespace_id }
  let(:project_id) { 128 }

  describe '#perform' do
    subject(:perform) { described_class.new.perform(root_namespace_id, project_id) }

    context 'when node_id is nil' do
      context 'when node_id can be found' do
        it 'executes delete_zoekt_index!' do
          expect(::Gitlab::Search::Zoekt::Client).to receive(:delete)
            .with(node_id: zoekt_node.id, project_id: project_id)

          perform
        end
      end

      context 'when node_id could not be found' do
        let(:root_namespace_id) { non_existing_record_id }

        it 'does not execute delete_zoekt_index!' do
          expect(::Gitlab::Search::Zoekt::Client).not_to receive(:delete)

          perform
        end
      end
    end

    context 'when node_id is set' do
      subject(:perform) { described_class.new.perform(root_namespace_id, project_id, zoekt_node.id) }

      it 'executes delete_zoekt_index!' do
        expect(::Search::Zoekt::Node).not_to receive(:for_namespace)
        expect(::Gitlab::Search::Zoekt::Client).to receive(:delete)
                                .with(node_id: zoekt_node.id, project_id: project_id)

        perform
      end
    end

    context 'when zoekt indexing is disabled' do
      before do
        stub_feature_flags(index_code_with_zoekt: false)
      end

      it 'does nothing' do
        expect(::Gitlab::Search::Zoekt::Client).not_to receive(:delete)

        perform
      end
    end
  end
end
