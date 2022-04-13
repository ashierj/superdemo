# frozen_string_literal: true
#
# The inverse of 20220412143551_add_partial_index_on_unencrypted_integrations.rb
class RemovePartialIndexOnUnencryptedIntegrations < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_integrations_on_id_where_not_encrypted'
  INDEX_FILTER_CONDITION = 'properties IS NOT NULL AND encrypted_properties IS NULL'

  def down
    add_concurrent_index :integrations, [:id],
      where: INDEX_FILTER_CONDITION,
      name: INDEX_NAME
  end

  def up
    remove_concurrent_index_by_name :integrations, INDEX_NAME
  end
end
