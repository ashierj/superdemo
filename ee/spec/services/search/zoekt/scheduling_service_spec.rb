# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Search::Zoekt::SchedulingService, feature_category: :global_search do
  let(:logger) { instance_double('Logger') }
  let(:service) { described_class.new(task.to_s) }
  let_it_be(:node) { create(:zoekt_node, :enough_free_space) }

  subject(:execute_task) { service.execute }

  before do
    allow(described_class).to receive(:logger).and_return(logger)
  end

  describe '.execute' do
    let(:task) { :foo }

    it 'executes the task' do
      expect(described_class).to receive(:new).with(task).and_return(service)
      expect(service).to receive(:execute)

      described_class.execute(task)
    end
  end

  describe '#execute' do
    let(:task) { :foo }

    it 'raises an exception when unknown task is provided' do
      expect { service.execute }.to raise_error(ArgumentError)
    end

    it 'raises an exception when the task is not implemented' do
      stub_const('::Search::Zoekt::SchedulingService::TASKS', [:foo])

      expect { service.execute }.to raise_error(NotImplementedError)
    end

    it 'converts string task to symbol' do
      expect(described_class.new(task.to_s).task).to eq(task.to_sym)
    end
  end

  describe '#remove_expired_subscriptions' do
    let(:task) { :remove_expired_subscriptions }

    it 'returns false unless saas' do
      expect(execute_task).to eq(false)
    end

    context 'when on .com', :saas do
      let_it_be(:expiration_date) { Date.today - Search::Zoekt::EXPIRED_SUBSCRIPTION_GRACE_PERIOD }
      let_it_be(:zkt_enabled_namespace) { create(:zoekt_enabled_namespace) }
      let_it_be(:zkt_enabled_namespace2) { create(:zoekt_enabled_namespace) }
      let_it_be(:subscription) { create(:gitlab_subscription, namespace: zkt_enabled_namespace2.namespace) }
      let_it_be(:expired_subscription) do
        create(:gitlab_subscription, namespace: zkt_enabled_namespace.namespace, end_date: expiration_date - 1.day)
      end

      it 'destroys zoekt_namespaces with expired subscriptions' do
        expect { execute_task }.to change { ::Search::Zoekt::EnabledNamespace.count }.by(-1)

        expect(::Search::Zoekt::EnabledNamespace.pluck(:id)).to contain_exactly(zkt_enabled_namespace2.id)
      end
    end
  end

  describe '#node_assignment' do
    let(:task) { :node_assignment }

    let_it_be(:namespace) { create(:group) }
    let_it_be(:namespace_statistics) { create(:namespace_root_storage_statistics, repository_size: 1000) }
    let_it_be(:namespace_with_statistics) { create(:group, root_storage_statistics: namespace_statistics) }

    context 'when some zoekt enabled namespaces missing zoekt index' do
      let(:logger) { instance_double(::Zoekt::Logger) }
      let_it_be(:zkt_enabled_namespace) { create(:zoekt_enabled_namespace, namespace: namespace.root_ancestor) }
      let_it_be(:zkt_enabled_namespace2) do
        create(:zoekt_enabled_namespace, namespace: namespace_with_statistics.root_ancestor)
      end

      before do
        allow(::Zoekt::Logger).to receive(:build).and_return(logger)
      end

      context 'when there is not enough space in any nodes' do
        before do
          node.update_column(:total_bytes, 100)
        end

        it 'does not creates a record of Search::Zoekt::Index for the namespace' do
          node_free_space = node.total_bytes - node.used_bytes
          expect(namespace_statistics.repository_size).to be > node_free_space
          expect(zkt_enabled_namespace.indices).to be_empty
          expect(zkt_enabled_namespace2.indices).to be_empty
          expect(Search::Zoekt::Node).to receive(:descending_order_by_free_bytes).and_call_original
          expect(logger).to receive(:error).with({ 'class' => described_class.to_s, 'task' => task,
                                                          'message' => "RootStorageStatistics isn't available",
                                                          'zoekt_enabled_namespace_id' => zkt_enabled_namespace.id }
          )
          expect(logger).to receive(:error).with({ 'class' => described_class.to_s, 'task' => task,
                                                          'node_id' => node.id,
                                                          'message' => 'Space is not available in Node',
                                                          'zoekt_enabled_namespace_id' => zkt_enabled_namespace2.id }
          )
          expect { execute_task }.not_to change { Search::Zoekt::Index.count }
          expect(zkt_enabled_namespace.indices).to be_empty
          expect(zkt_enabled_namespace2.indices).to be_empty
        end

        context 'when there is space for the repository but not for the WATERMARK_LIMIT' do
          before do
            node.update_column(:total_bytes,
              (namespace_statistics.repository_size * described_class::BUFFER_FACTOR) + node.used_bytes)
          end

          it 'does not creates a record of Search::Zoekt::Index for the namespace' do
            node_free_space = node.total_bytes - node.used_bytes
            # Assert that node's free space is equal to the repository_size times BUFFER_FACTOR
            expect(namespace_statistics.repository_size * described_class::BUFFER_FACTOR).to eq node_free_space
            expect(zkt_enabled_namespace.indices).to be_empty
            expect(zkt_enabled_namespace2.indices).to be_empty
            expect(Search::Zoekt::Node).to receive(:descending_order_by_free_bytes).and_call_original
            expect(logger).to receive(:error).with({ 'class' => described_class.to_s, 'task' => task,
                                                    'message' => "RootStorageStatistics isn't available",
                                                    'zoekt_enabled_namespace_id' => zkt_enabled_namespace.id }
            )
            expect(logger).to receive(:error).with({ 'class' => described_class.to_s, 'task' => task,
                                                    'node_id' => node.id,
                                                    'message' => 'Space is not available in Node',
                                                    'zoekt_enabled_namespace_id' => zkt_enabled_namespace2.id }
            )
            expect { execute_task }.not_to change { Search::Zoekt::Index.count }
            expect(zkt_enabled_namespace.indices).to be_empty
            expect(zkt_enabled_namespace2.indices).to be_empty
          end
        end
      end

      context 'when there is enough space in the node' do
        context 'when a new record of Search::Zoekt::Index could not be saved' do
          it 'logs error' do
            expect(zkt_enabled_namespace.indices).to be_empty
            expect(zkt_enabled_namespace2.indices).to be_empty
            expect(Search::Zoekt::Node).to receive(:descending_order_by_free_bytes).and_call_original
            expect(logger).to receive(:error).with({ 'class' => described_class.to_s, 'task' => task,
                                                    'message' => "RootStorageStatistics isn't available",
                                                    'zoekt_enabled_namespace_id' => zkt_enabled_namespace.id }
            )
            allow_next_instance_of(Search::Zoekt::Index) do |instance|
              allow(instance).to receive(:valid?).and_return(false)
            end
            expect(logger).to receive(:error).with(hash_including('zoekt_index', 'class' => described_class.to_s,
              'task' => task, 'message' => 'Could not save Search::Zoekt::Index'))
            expect { execute_task }.not_to change { Search::Zoekt::Index.count }
            expect(zkt_enabled_namespace.indices).to be_empty
            expect(zkt_enabled_namespace2.indices).to be_empty
          end
        end

        it 'creates a record of Search::Zoekt::Index for the namespace which has statistics' do
          expect(zkt_enabled_namespace.indices).to be_empty
          expect(zkt_enabled_namespace2.indices).to be_empty
          expect(Search::Zoekt::Node).to receive(:descending_order_by_free_bytes).and_call_original
          expect(logger).to receive(:error).with({ 'class' => described_class.to_s, 'task' => task,
                                                  'message' => "RootStorageStatistics isn't available",
                                                  'zoekt_enabled_namespace_id' => zkt_enabled_namespace.id }
          )
          expect { execute_task }.to change { Search::Zoekt::Index.count }.by(1)
          expect(zkt_enabled_namespace.indices).to be_empty
          index = zkt_enabled_namespace2.indices.last
          expect(index).not_to be_nil
          expect(index.namespace_id).to eq zkt_enabled_namespace2.root_namespace_id
          expect(index).to be_ready
        end
      end
    end
  end
end
