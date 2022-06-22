# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillProjectStatisticsWithContainerRegistrySize do
  let_it_be(:batched_migration) { described_class::MIGRATION_CLASS }

  it 'schedules background jobs for each batch of container_repository' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          table_name: :container_repositories,
          column_name: :project_id,
          interval: described_class::DELAY_INTERVAL
        )
      }
    end
  end
end
