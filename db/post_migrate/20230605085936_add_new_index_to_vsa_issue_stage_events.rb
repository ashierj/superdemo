# frozen_string_literal: true

class AddNewIndexToVsaIssueStageEvents < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  TABLE_NAME = :analytics_cycle_analytics_issue_stage_events
  COLUMN_NAMES = %I[stage_event_hash_id group_id end_event_timestamp issue_id].freeze
  INDEX_NAME = 'index_issue_stage_events_for_consistency_check'

  disable_ddl_transaction!

  def up
    add_concurrent_partitioned_index TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME
  end

  def down
    remove_concurrent_partitioned_index_by_name TABLE_NAME, INDEX_NAME
  end
end
