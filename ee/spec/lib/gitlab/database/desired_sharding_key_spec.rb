# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'new tables missing sharding_key', feature_category: :cell do
  let(:allowed_sharding_key_referenced_tables) { %w[projects namespaces organizations] }
  let(:connection) { ApplicationRecord.connection }

  it 'must reference an allowed referenced table' do
    desired_sharding_key_entries.each do |entry|
      entry.desired_sharding_key.each do |_column, details|
        references = details['references']
        expect(references).to be_in(allowed_sharding_key_referenced_tables),
          error_message_incorrect_reference(entry.table_name, references)
      end
    end
  end

  it 'must be possible to backfill it via backfill_via' do
    desired_sharding_key_entries.each do |entry|
      entry.desired_sharding_key.each do |desired_column, details|
        table = entry.table_name
        sharding_key = desired_column
        parent = details['backfill_via']['parent']
        foreign_key = parent['foreign_key']
        parent_table = parent['table']
        parent_sharding_key = parent['sharding_key']

        connection.execute("ALTER TABLE #{table} ADD COLUMN #{sharding_key} bigint")

        # Confirming it at least produces a valid query
        connection.execute <<~SQL
                           UPDATE #{table}
                           SET #{sharding_key} = #{parent_table}.#{parent_sharding_key}
                           FROM #{parent_table}
                           WHERE #{table}.#{foreign_key} = #{parent_table}.id
        SQL
      end
    end
  end

  it 'the parent.belongs_to must be a model with the parent.sharding_key column' do
    desired_sharding_key_entries.each do |entry|
      model = entry.classes.first.constantize
      entry.desired_sharding_key.each do |_column, details|
        parent = details['backfill_via']['parent']
        parent_sharding_key = parent['sharding_key']
        belongs_to = parent['belongs_to']
        parent_association = model.reflect_on_association(belongs_to)
        expect(parent_association).not_to be_nil,
          "Invalid backfil_via.parent.belongs_to: #{belongs_to} in db/docs for #{entry.table_name}"
        parent_columns = parent_association.class_name.constantize.columns.map(&:name)

        expect(parent_columns).to include(parent_sharding_key)
      end
    end
  end

  private

  def error_message_incorrect_reference(table_name, references)
    <<~HEREDOC
    The table `#{table_name}` has an invalid `desired_sharding_key` in the `db/docs` YML file. The column references `#{references}` but it must reference one of `#{allowed_sharding_key_referenced_tables.join(', ')}`.

      To choose an appropriate desired_sharding_key for this table please refer
      to our guidelines at https://docs.gitlab.com/ee/development/database/multiple_databases.html#defining-a-desired-sharding-key, or consult with the Tenant Scale group.
    HEREDOC
  end

  def desired_sharding_key_entries
    ::Gitlab::Database::Dictionary.entries.select do |entry|
      entry.desired_sharding_key.present?
    end
  end

  def valid_backfill_via?
    sql = <<~SQL
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public' AND
    table_name = '#{table_name}' AND
    column_name = '#{column_name}';
    SQL

    result = ApplicationRecord.connection.execute(sql)

    result.count > 0
  end
end
