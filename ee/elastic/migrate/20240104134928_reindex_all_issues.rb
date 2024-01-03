# frozen_string_literal: true

class ReindexAllIssues < Elastic::Migration
  include ::Search::Elastic::MigrationDatabaseBackfillHelper

  batch_size 10_000
  batched!
  throttle_delay 1.minute
  retry_on_failure

  DOCUMENT_TYPE = Issue

  def respect_limited_indexing?
    true
  end
end
