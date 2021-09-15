# frozen_string_literal: true

class DropTemporaryColumnsAndTriggersForCiBuildNeeds < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  TABLE = 'ci_build_needs'
  TEMPORARY_COLUMN = 'build_id_convert_to_bigint'
  MAIN_COLUMN = 'build_id'

  # rubocop:disable Migration/WithLockRetriesDisallowedMethod
  def up
    with_lock_retries do
      cleanup_conversion_of_integer_to_bigint(TABLE, MAIN_COLUMN)
    end
  end

  def down
    check_trigger_permissions!(TABLE)

    with_lock_retries do
      add_column(TABLE, TEMPORARY_COLUMN, :int, default: 0, null: false)
      install_rename_triggers(TABLE, MAIN_COLUMN, TEMPORARY_COLUMN)
    end
  end
  # rubocop:enable Migration/WithLockRetriesDisallowedMethod
end
