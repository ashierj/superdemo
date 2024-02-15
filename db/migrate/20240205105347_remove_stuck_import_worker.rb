# frozen_string_literal: true

class RemoveStuckImportWorker < Gitlab::Database::Migration[2.2]
  milestone '16.10'
  disable_ddl_transaction!

  DEPRECATED_JOB_CLASSES = %w[
    BulkImports::StuckImportWorker
  ]

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes any instances of deprecated workers and cannot be undone.
  end
end
