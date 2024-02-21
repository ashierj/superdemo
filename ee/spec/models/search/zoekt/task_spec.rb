# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Search::Zoekt::Task, feature_category: :global_search do
  subject(:task) { create(:zoekt_task) }

  describe 'relations' do
    it { is_expected.to belong_to(:node).inverse_of(:tasks) }
    it { is_expected.to belong_to(:zoekt_repository).inverse_of(:tasks) }
  end

  describe 'sliding_list partitioning' do
    let(:partition_manager) { Gitlab::Database::Partitioning::PartitionManager.new(described_class) }

    describe 'next_partition_if callback' do
      let(:active_partition) { described_class.partitioning_strategy.active_partition }

      subject(:value) { described_class.partitioning_strategy.next_partition_if.call(active_partition) }

      context 'when the partition is empty' do
        it { is_expected.to eq(false) }
      end

      context 'when the partition has records' do
        before do
          create(:zoekt_task, state: :pending)
          create(:zoekt_task, state: :done)
          create(:zoekt_task, state: :failed)
        end

        it { is_expected.to eq(false) }

        context 'when the first record of the partition is older than PARTITION_DURATION' do
          before do
            described_class.first.update!(created_at: (described_class::PARTITION_DURATION + 1.day).ago)
          end

          it { is_expected.to eq(true) }
        end
      end
    end

    describe 'detach_partition_if callback' do
      let(:active_partition) { described_class.partitioning_strategy.active_partition }

      subject(:value) { described_class.partitioning_strategy.detach_partition_if.call(active_partition) }

      before_all do
        create(:zoekt_task, state: :pending)
        create(:zoekt_task, state: :done)
      end

      context 'when the partition contains unprocessed records' do
        it { is_expected.to eq(false) }
      end

      context 'when the partition contains only processed records' do
        before do
          described_class.update_all(state: :done)
        end

        it { is_expected.to eq(true) }
      end
    end
  end
end
