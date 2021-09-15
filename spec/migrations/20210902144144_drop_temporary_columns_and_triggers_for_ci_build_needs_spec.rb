# frozen_string_literal: true

require 'spec_helper'
require_migration!('drop_temporary_columns_and_triggers_for_ci_build_needs')

RSpec.describe DropTemporaryColumnsAndTriggersForCiBuildNeeds do
  let(:ci_build_needs_table) { table(:ci_build_needs) }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(ci_build_needs_table.column_names).to include('build_id_convert_to_bigint')
      }

      migration.after -> {
        ci_build_needs_table.reset_column_information
        expect(ci_build_needs_table.column_names).not_to include('build_id_convert_to_bigint')
      }
    end
  end
end
