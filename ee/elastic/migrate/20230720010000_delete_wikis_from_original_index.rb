# frozen_string_literal: true

class DeleteWikisFromOriginalIndex < Elastic::Migration
  include Elastic::MigrationHelper

  batched!
  retry_on_failure

  def migrate
    task_id = migration_state[:task_id]
    if task_id
      task_status = helper.task_status(task_id: task_id)
      log_raise 'Failed to delete wikis', task_id: task_id, error: task_status['error'] if task_status['error'].present?

      if task_status['completed']
        log 'Removing wikis from the original index is completed for a specific task', task_id: task_id
        set_migration_state(task_id: nil, documents_remaining: 0)
      else
        log 'Removing wikis from the original index is still in progress for a specific task', task_id: task_id
      end

      return
    end

    if completed?
      log 'There are no wikis to remove from original index'
      return
    end

    log 'Launching delete by query'
    response = client.delete_by_query(index: helper.target_name, conflicts: 'proceed', wait_for_completion: false,
      body: { query: { bool: { filter: { term: { type: 'wiki_blob' } } } } },
      slices: get_number_of_shards(index_name: helper.target_name)
    )
    task_id = response['task']
    log 'Removing wikis from the original index is started for a task', task_id: task_id
    set_migration_state(task_id: task_id, documents_remaining: original_documents_count)
  rescue StandardError => e
    set_migration_state(task_id: nil, documents_remaining: original_documents_count)
    raise e
  end

  def completed?
    helper.refresh_index
    total_remaining = original_documents_count
    log 'Checking if migration is completed based on documents counts remaining', remaining: total_remaining
    total_remaining == 0
  end

  private

  def document_type
    :wiki_blob
  end
end
