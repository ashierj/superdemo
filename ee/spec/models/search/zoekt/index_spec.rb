# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Search::Zoekt::Index, feature_category: :global_search do
  let_it_be(:namespace) { create(:group) }
  let_it_be_with_reload(:zoekt_enabled_namespace) { create(:zoekt_enabled_namespace, namespace: namespace) }
  let_it_be(:zoekt_node) { create(:zoekt_node) }
  let_it_be(:zoekt_index) do
    create(:zoekt_index, zoekt_enabled_namespace: zoekt_enabled_namespace, node: zoekt_node)
  end

  subject { zoekt_index }

  describe 'relations' do
    it { is_expected.to belong_to(:zoekt_enabled_namespace).inverse_of(:indices) }
    it { is_expected.to belong_to(:node).inverse_of(:indices) }
    it { is_expected.to have_many(:zoekt_repositories).inverse_of(:zoekt_index) }
  end

  describe 'validations' do
    it 'validates that zoekt_enabled_namespace root_namespace_id matches namespace_id' do
      zoekt_index = described_class.new(zoekt_enabled_namespace: zoekt_enabled_namespace,
        node: zoekt_node, namespace_id: 0)
      expect(zoekt_index).to be_invalid
    end
  end

  describe 'callbacks' do
    let_it_be(:another_enabled_namespace) { create(:zoekt_enabled_namespace) }

    describe '#create!' do
      it 'triggers indexing for the namespace' do
        expect(::Search::Zoekt::NamespaceIndexerWorker).to receive(:perform_async)
          .with(another_enabled_namespace.root_namespace_id, :index)

        described_class.create!(zoekt_enabled_namespace: another_enabled_namespace, node: zoekt_node,
          namespace_id: another_enabled_namespace.root_namespace_id)
      end
    end

    describe '#destroy!' do
      it 'removes index for the namespace' do
        another_zoekt_index = create(:zoekt_index, zoekt_enabled_namespace: another_enabled_namespace,
          namespace_id: another_enabled_namespace.root_namespace_id)

        expect(::Search::Zoekt::NamespaceIndexerWorker).to receive(:perform_async)
          .with(another_enabled_namespace.root_namespace_id, :delete, another_zoekt_index.zoekt_node_id)

        another_zoekt_index.destroy!
      end
    end
  end

  describe 'scopes' do
    let_it_be(:namespace_2) { create(:group) }
    let_it_be_with_reload(:zoekt_enabled_namespace_2) { create(:zoekt_enabled_namespace, namespace: namespace_2) }
    let_it_be(:node_2) { create(:zoekt_node) }
    let_it_be(:zoekt_index_2) do
      create(:zoekt_index, node: node_2, zoekt_enabled_namespace: zoekt_enabled_namespace_2)
    end

    describe '#for_node' do
      subject { described_class.for_node(node_2) }

      it { is_expected.to contain_exactly(zoekt_index_2) }
    end

    describe '#for_root_namespace_id' do
      subject { described_class.for_root_namespace_id(namespace_2) }

      it { is_expected.to contain_exactly(zoekt_index_2) }
    end

    describe '#for_root_namespace_id_with_search_enabled' do
      it 'correctly filters on the search field' do
        expect(described_class.for_root_namespace_id_with_search_enabled(namespace_2))
          .to contain_exactly(zoekt_index_2)

        zoekt_enabled_namespace_2.update!(search: false)

        expect(described_class.for_root_namespace_id_with_search_enabled(namespace_2))
          .to be_empty
      end
    end
  end
end
