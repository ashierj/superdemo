# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Search::Zoekt::Index, feature_category: :global_search do
  let_it_be(:zoekt_enabled_namespace) { create(:zoekt_enabled_namespace) }
  let_it_be(:node) { create(:zoekt_node) }

  subject { create(:zoekt_index, zoekt_enabled_namespace: zoekt_enabled_namespace, node: zoekt_node) }

  describe 'relations' do
    it { is_expected.to belong_to(:zoekt_enabled_namespace).inverse_of(:indices) }
    it { is_expected.to belong_to(:node).inverse_of(:indices) }
  end

  describe 'validations' do
    it 'validates that zoekt_enabled_namespace root_namespace_id matches namespace_id' do
      zoekt_index = described_class.new(zoekt_enabled_namespace: zoekt_enabled_namespace,
        node: zoekt_node, namespace_id: 0)
      expect(zoekt_index).to be_invalid
    end
  end

  describe 'callbacks' do
    let_it_be(:zoekt_node) { create(:zoekt_node) }

    describe '#create!' do
      it 'triggers indexing for the namespace' do
        expect(::Search::Zoekt::NamespaceIndexerWorker).to receive(:perform_async)
          .with(zoekt_enabled_namespace.root_namespace_id, :index)

        described_class.create!(zoekt_enabled_namespace: zoekt_enabled_namespace, node: zoekt_node,
          namespace_id: zoekt_enabled_namespace.root_namespace_id)
      end
    end

    describe '#destroy!' do
      let_it_be(:zoekt_index) { create(:zoekt_index, zoekt_enabled_namespace: zoekt_enabled_namespace) }

      it 'removes index for the namespace' do
        expect(::Search::Zoekt::NamespaceIndexerWorker).to receive(:perform_async)
          .with(zoekt_enabled_namespace.root_namespace_id, :delete, zoekt_index.zoekt_node_id)

        zoekt_index.destroy!
      end
    end
  end
end
