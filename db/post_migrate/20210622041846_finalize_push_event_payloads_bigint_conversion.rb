# frozen_string_literal: true

class FinalizePushEventPayloadsBigintConversion < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  TABLE_NAME = 'push_event_payloads'
  INDEX_NAME = 'index_push_event_payloads_on_event_id_convert_to_bigint'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
      table_name: 'push_event_payloads',
      column_name: 'event_id',
      job_arguments: [["event_id"], ["event_id_convert_to_bigint"]]
    )

    swap_columns
  end

  def down
    swap_columns
  end

  private

  def swap_columns
    add_concurrent_index TABLE_NAME, :event_id_convert_to_bigint, unique: true, name: INDEX_NAME

    # Duplicate fk_36c74129da FK
    add_concurrent_foreign_key TABLE_NAME, :events, column: :event_id_convert_to_bigint, on_delete: :cascade

    with_lock_retries(raise_on_exhaustion: true) do
      swap_column_names TABLE_NAME, :event_id, :event_id_convert_to_bigint # rubocop:disable Migration/WithLockRetriesDisallowedMethod

      # Swap defaults
      change_column_default TABLE_NAME, :event_id, nil
      change_column_default TABLE_NAME, :event_id_convert_to_bigint, 0

      # Swap PK constraint
      execute "ALTER TABLE #{TABLE_NAME} DROP CONSTRAINT push_event_payloads_pkey"
      rename_index TABLE_NAME, INDEX_NAME, 'push_event_payloads_pkey'
      execute "ALTER TABLE #{TABLE_NAME} ADD CONSTRAINT push_event_payloads_pkey PRIMARY KEY USING INDEX push_event_payloads_pkey"

      # Drop FK fk_36c74129da
      remove_foreign_key TABLE_NAME, name: concurrent_foreign_key_name(TABLE_NAME, :event_id)
      # Change the name of the FK for event_id_convert_to_bigint to the FK name for event_id
      rename_constraint(
        TABLE_NAME,
        concurrent_foreign_key_name(TABLE_NAME, :event_id_convert_to_bigint),
        concurrent_foreign_key_name(TABLE_NAME, :event_id)
      )
    end
  end
end
