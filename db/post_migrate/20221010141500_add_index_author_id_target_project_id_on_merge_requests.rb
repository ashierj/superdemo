# frozen_string_literal: true

class AddIndexAuthorIdTargetProjectIdOnMergeRequests < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_merge_requests_on_author_id_and_target_project_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_requests, %i[author_id target_project_id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :merge_requests, INDEX_NAME
  end
end
