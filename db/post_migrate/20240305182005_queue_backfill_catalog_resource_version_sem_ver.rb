# frozen_string_literal: true

class QueueBackfillCatalogResourceVersionSemVer < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'BackfillCatalogResourceVersionSemVer'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 500
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :catalog_resource_versions,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :catalog_resource_versions, :id, [])
  end
end
