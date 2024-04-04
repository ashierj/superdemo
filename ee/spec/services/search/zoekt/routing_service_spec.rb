# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Search::Zoekt::RoutingService, feature_category: :global_search do
  let(:service) { described_class.new(projects) }

  let_it_be(:ns_1) { create(:namespace) }
  let_it_be(:ns_2) { create(:namespace) }

  let_it_be(:project_1) { create(:project, namespace: ns_1) }
  let_it_be(:project_2) { create(:project, namespace: ns_2) }
  let(:projects) { Project.where(id: [project_1.id, project_2.id]) }

  subject(:execute_task) { service.execute }

  describe '.execute' do
    it 'executes the task' do
      expect(described_class).to receive(:new).with(projects).and_return(service)
      expect(service).to receive(:execute)

      described_class.execute(projects)
    end
  end

  describe '#execute' do
    let_it_be(:node_1) { create(:zoekt_node, :enough_free_space) }
    let_it_be(:node_2) { create(:zoekt_node, :enough_free_space) }
    let_it_be(:zoekt_enabled_namespace_1) { create(:zoekt_enabled_namespace, namespace: ns_1) }
    let_it_be(:zoekt_enabled_namespace_2) { create(:zoekt_enabled_namespace, namespace: ns_2) }

    let_it_be(:zoekt_index_1) do
      create(:zoekt_index, zoekt_enabled_namespace: zoekt_enabled_namespace_1, node: node_1, state: :ready)
    end

    let_it_be(:zoekt_index_2) do
      create(:zoekt_index, zoekt_enabled_namespace: zoekt_enabled_namespace_2, node: node_2, state: :ready)
    end

    it 'returns correct map' do
      expect(execute_task).to eq(
        {
          node_1.id => [project_1.id],
          node_2.id => [project_2.id]
        })
    end
  end
end
