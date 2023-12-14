# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Search::Zoekt, feature_category: :global_search do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:node) { create(:zoekt_node) }
  let_it_be_with_reload(:indexed_namespace) { create(:zoekt_indexed_namespace, node: node, namespace: group) }

  describe '#fetch_node_id' do
    subject(:fetch_node_id) { described_class.fetch_node_id(container) }

    context 'when passed a project' do
      let(:container) { project }

      it { is_expected.to eq(node.id) }
    end

    context 'when passed a namespace' do
      let(:container) { group }

      it { is_expected.to eq(node.id) }
    end

    context 'when passed a subgroup' do
      let(:container) { create(:group, parent: group) }

      it { is_expected.to eq(node.id) }
    end

    context 'when passed a namespace id' do
      let(:container) { group.id }

      it { is_expected.to eq(node.id) }
    end

    context 'when Zoekt::IndexedNamespace not found' do
      let(:container) { non_existing_record_id }

      it { is_expected.to be_nil }
    end

    context 'when passed an unsupported class' do
      let(:container) { instance_double(Issue) }

      it { expect { fetch_node_id }.to raise_error(ArgumentError) }
    end
  end

  describe '#search?' do
    subject(:search) { described_class.search?(container) }

    [true, false].each do |search|
      context "when search on the indexed_namespace is set to #{search}" do
        before do
          indexed_namespace.update!(search: search)
        end

        context 'when passed a project' do
          let(:container) { project }

          it { is_expected.to eq(search) }
        end

        context 'when passed a namespace' do
          let(:container) { group }

          it { is_expected.to eq(search) }
        end
      end
    end

    context 'when Zoekt::IndexedNamespace not found' do
      let(:container) { build(:project) }

      it { is_expected.to eq(false) }
    end

    context 'when passed an unsupported class' do
      let(:container) { instance_double(Issue) }

      it { expect { search }.to raise_error(ArgumentError) }
    end
  end

  describe '#index?' do
    subject(:index) { described_class.index?(container) }

    context 'when passed a project' do
      let(:container) { project }

      it { is_expected.to eq(true) }
    end

    context 'when passed a namespace' do
      let(:container) { group }

      it { is_expected.to eq(true) }
    end

    context 'when Zoekt::IndexedNamespace not found' do
      let(:container) { build(:project) }

      it { is_expected.to eq(false) }
    end

    context 'when passed an unsupported class' do
      let(:container) { instance_double(Issue) }

      it { expect { index }.to raise_error(ArgumentError) }
    end
  end
end
