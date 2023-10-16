# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Zoekt::Shard, feature_category: :global_search do
  let_it_be(:indexed_namespace1) { create(:namespace) }
  let_it_be(:indexed_namespace2) { create(:namespace) }
  let_it_be(:unindexed_namespace) { create(:namespace) }
  let(:shard) { described_class.create!(index_base_url: 'http://example.com:1234/', search_base_url: 'http://example.com:4567/') }

  before do
    create(:zoekt_indexed_namespace, shard: shard, namespace: indexed_namespace1)
    create(:zoekt_indexed_namespace, shard: shard, namespace: indexed_namespace2)
  end

  it 'has many indexed_namespaces' do
    expect(shard.indexed_namespaces.count).to eq(2)
    expect(shard.indexed_namespaces.map(&:namespace)).to contain_exactly(indexed_namespace1, indexed_namespace2)
  end

  describe '.for_namespace' do
    it 'returns associated shard' do
      expect(described_class.for_namespace(root_namespace_id: indexed_namespace1.id)).to eq(shard)
    end

    it 'returns nil when no shard is associated' do
      expect(described_class.for_namespace(root_namespace_id: unindexed_namespace.id)).to be_nil
    end
  end

  describe '.find_or_initialize_by_task_request', :freeze_time do
    let(:params) do
      {
        'uuid' => '3869fe21-36d1-4612-9676-0b783ef2dcd7',
        'node.name' => 'm1.local',
        'node.url' => 'http://localhost:6090',
        'disk.all' => 994662584320,
        'disk.used' => 532673712128,
        'disk.free' => 461988872192
      }
    end

    subject(:tasked_shard) { described_class.find_or_initialize_by_task_request(params) }

    context 'when shard does not exist for given UUID' do
      it 'returns a new record with correct attributes' do
        expect(tasked_shard).not_to be_persisted
        expect(tasked_shard.index_base_url).to eq(params['node.url'])
        expect(tasked_shard.search_base_url).to eq(params['node.url'])
        expect(tasked_shard.uuid).to eq(params['uuid'])
        expect(tasked_shard.last_seen_at).to eq(Time.zone.now)
        expect(tasked_shard.used_bytes).to eq(params['disk.used'])
        expect(tasked_shard.total_bytes).to eq(params['disk.all'])
        expect(tasked_shard.metadata['name']).to eq(params['node.name'])
      end
    end

    context 'when shard already exists for given UUID' do
      it 'returns existing shard and updates correct attributes' do
        shard.update!(uuid: params['uuid'])

        expect(tasked_shard).to be_persisted
        expect(tasked_shard.id).to eq(shard.id)
        expect(tasked_shard.index_base_url).to eq(params['node.url'])
        expect(tasked_shard.search_base_url).to eq(params['node.url'])
        expect(tasked_shard.uuid).to eq(params['uuid'])
        expect(tasked_shard.last_seen_at).to eq(Time.zone.now)
        expect(tasked_shard.used_bytes).to eq(params['disk.used'])
        expect(tasked_shard.total_bytes).to eq(params['disk.all'])
        expect(tasked_shard.metadata['name']).to eq(params['node.name'])
      end
    end
  end
end
