# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Search::Zoekt::SchedulingWorker, feature_category: :global_search do
  it_behaves_like 'worker with data consistency', described_class, data_consistency: :always

  describe '#perform' do
    subject(:execute_worker) { described_class.new.perform(task) }

    let_it_be(:node) { create(:zoekt_node, :enough_free_space) }

    context 'when feature flag zoekt_scheduling_worker is disabled' do
      let(:task) { :initate }

      it_behaves_like 'an idempotent worker' do
        before do
          stub_feature_flags(zoekt_scheduling_worker: false)
        end

        it 'returns false' do
          expect(execute_worker).to be false
        end
      end
    end

    context 'when task is initiate' do
      let(:task) { :initiate }

      it_behaves_like 'an idempotent worker' do
        it 'calls the worker with each supported tasks' do
          described_class::TASKS.each { |t| expect(described_class).to receive(:perform_async).with(t) }
          execute_worker
        end
      end
    end

    context 'when task is not supported' do
      let(:task) { :dummy }

      it_behaves_like 'an idempotent worker' do
        it 'calls the worker with each supported tasks' do
          expect { execute_worker }.to raise_error(ArgumentError, "Unknown task: #{task}")
        end
      end
    end

    context 'when task is node_assignment' do
      let(:task) { :node_assignment }
      let_it_be(:namespace) { create(:group) }
      let_it_be(:namespace_statistics) { create(:namespace_root_storage_statistics, repository_size: 1000) }
      let_it_be(:namespace_with_statistics) { create(:group, root_storage_statistics: namespace_statistics) }

      context 'when all zoekt enabled namespaces has the index' do
        it_behaves_like 'an idempotent worker' do
          before do
            [namespace, namespace_with_statistics].each { |n| zoekt_ensure_namespace_indexed!(n) }
          end

          it 'does not creates Search::Zoekt::Index record' do
            expect(Search::Zoekt::Node).not_to receive(:descending_order_and_select_by_free_bytes)
            expect { execute_worker }.not_to change { Search::Zoekt::Index.count }
          end
        end
      end

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
            expect { execute_worker }.not_to change { Search::Zoekt::Index.count }
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
              expect { execute_worker }.not_to change { Search::Zoekt::Index.count }
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
              expect { execute_worker }.not_to change { Search::Zoekt::Index.count }
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
            expect { execute_worker }.to change { Search::Zoekt::Index.count }.by(1)
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
end
