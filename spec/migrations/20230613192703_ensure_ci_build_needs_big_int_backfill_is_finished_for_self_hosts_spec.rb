# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe EnsureCiBuildNeedsBigIntBackfillIsFinishedForSelfHosts, migration: :gitlab_ci, feature_category: :continuous_integration do
  describe '#up' do
    let(:migration_arguments) do
      {
        job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
        table_name: 'ci_build_needs',
        column_name: 'id',
        job_arguments: [['id'], ['id_convert_to_bigint']]
      }
    end

    it 'ensures the migration is completed' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:ensure_batched_background_migration_is_finished).with(migration_arguments)
      end

      migrate!
    end
  end
end
