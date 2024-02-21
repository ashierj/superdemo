# frozen_string_literal: true

module Search
  module Zoekt
    class Task < ApplicationRecord
      PARTITION_DURATION = 1.day

      include PartitionedTable
      include IgnorableColumns

      self.table_name = 'zoekt_tasks'
      self.primary_key = :id

      ignore_column :partition_id, remove_never: true

      belongs_to :node, foreign_key: :zoekt_node_id, inverse_of: :tasks, class_name: '::Search::Zoekt::Node'
      belongs_to :zoekt_repository, inverse_of: :tasks, class_name: '::Search::Zoekt::Repository'

      scope :for_partition, ->(partition) { where(partition_id: partition) }

      enum state: {
        pending: 0,
        done: 10,
        failed: 255,
        orphaned: 256
      }

      enum task_type: {
        index_repo: 0,
        force_index_repo: 1,
        delete_repo: 50
      }

      partitioned_by :partition_id,
        strategy: :sliding_list,
        next_partition_if: ->(active_partition) do
          oldest_record_in_partition = Task
            .select(:id, :created_at)
            .for_partition(active_partition.value)
            .order(:id)
            .first

          oldest_record_in_partition.present? &&
            oldest_record_in_partition.created_at < PARTITION_DURATION.ago
        end,
        detach_partition_if: ->(partition) do
          !Task
            .for_partition(partition.value)
            .where(state: :pending)
            .exists?
        end
    end
  end
end
