# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::Zoekt::IndexedNamespacesFinder, feature_category: :global_search do
  describe '.execute' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project_namespace) { create(:project_namespace) }
    let_it_be(:user_namespace) { create(:user_namespace) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:sub_group) { create(:group, parent: group) }
    let_it_be(:indexed_group_namespace) { create(:zoekt_indexed_namespace, namespace: group) }
    let_it_be(:indexed_user_namespace) { create(:zoekt_indexed_namespace, namespace: user_namespace) }
    let_it_be(:indexed_namespace_2) { create(:zoekt_indexed_namespace) }

    let(:params) { {} }

    subject(:execute) { described_class.new(params: params, container: container).execute }

    context 'when container is not passed' do
      let(:container) { nil }

      it { is_expected.to contain_exactly(indexed_group_namespace, indexed_namespace_2, indexed_user_namespace) }
    end

    context 'when container is passed a project' do
      let(:container) { project }

      it { is_expected.to contain_exactly(indexed_group_namespace) }
    end

    context 'when container is passed a root namespace' do
      let(:container) { group }

      it { is_expected.to contain_exactly(indexed_group_namespace) }
    end

    context 'when container is passed a project namespace' do
      let(:container) { project_namespace }

      # project namespaces cannot be indexed due to not have a root_ancestor
      it { is_expected.to be_empty }
    end

    context 'when container is passed a user namespace' do
      let(:container) { user_namespace }

      it { is_expected.to contain_exactly(indexed_user_namespace) }
    end

    context 'when container is passed a sub group' do
      let(:container) { sub_group }

      it { is_expected.to contain_exactly(indexed_group_namespace) }
    end

    context 'when container is not indexed' do
      let(:container) { create(:group) }

      it { is_expected.to be_empty }
    end

    describe 'params' do
      describe 'search' do
        let(:container) { nil }
        let(:params) { { search: true } }

        before do
          indexed_namespace_2.update!(search: false)
        end

        it { is_expected.to contain_exactly(indexed_group_namespace, indexed_user_namespace) }
      end
    end
  end
end
