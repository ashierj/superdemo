# frozen_string_literal: true

class BackfillHashedRootNamespaceIdOnNotes < Elastic::Migration
  include Elastic::MigrationBackfillHelper

  batched!
  batch_size 9_000
  throttle_delay 1.minute

  DOCUMENT_TYPE = Note
  UPDATE_BATCH_SIZE = 100

  private

  def field_name
    'hashed_root_namespace_id'
  end
end
