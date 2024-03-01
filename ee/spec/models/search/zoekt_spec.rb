# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Search::Zoekt, feature_category: :global_search do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:node) { create(:zoekt_node) }
  let_it_be_with_reload(:enabled_namespace) { create(:zoekt_enabled_namespace, namespace: group) }
  let_it_be_with_reload(:index) do
    create(:zoekt_index, :ready, zoekt_enabled_namespace: enabled_namespace, node: node)
  end

  let_it_be(:unassigned_group) { create(:group) }
  let_it_be_with_reload(:enabled_namespace_without_index) do
    create(:zoekt_enabled_namespace, namespace: unassigned_group)
  end

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
      let(:container) { subgroup }

      it { is_expected.to eq(node.id) }
    end

    context 'when passed a root namespace id' do
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
      context "when search on the zoekt_enabled_namespace is set to #{search}" do
        before do
          enabled_namespace.update!(search: search)
        end

        context 'when passed a project' do
          let(:container) { project }

          it { is_expected.to eq(search) }
        end

        context 'when passed a namespace' do
          let(:container) { group }

          it { is_expected.to eq(search) }
        end

        context 'when passed a subgroup' do
          let(:container) { subgroup }

          it { is_expected.to eq(search) }
        end

        context 'when passed a root namespace id' do
          let(:container) { group.id }

          it { is_expected.to eq(search) }
        end
      end
    end

    context 'when no indices are ready' do
      let(:container) { project }

      before do
        index.update!(state: :initializing)
      end

      it { is_expected.to eq(false) }
    end

    context 'when Zoekt::EnabledNamespace not found' do
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

    context 'when passed a root namespace id' do
      let(:container) { group.id }

      it { is_expected.to eq(true) }
    end

    context 'when Zoekt::Index is not found' do
      let(:container) { build(:project) }

      it { is_expected.to eq(false) }
    end

    context 'when passed an unsupported class' do
      let(:container) { instance_double(Issue) }

      it { expect { index }.to raise_error(ArgumentError) }
    end

    context 'when group is unassigned' do
      let(:container) { unassigned_group }

      it { is_expected.to eq(false) }
    end
  end
end
