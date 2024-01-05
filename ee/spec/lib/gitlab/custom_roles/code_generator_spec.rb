# frozen_string_literal: true

require 'spec_helper'
require 'active_support/testing/stream'

RSpec.describe Gitlab::CustomRoles::CodeGenerator, :migration, :silence_stdout,
  feature_category: :permissions do
  include ActiveSupport::Testing::Stream
  include MigrationsHelpers

  before do
    allow(MemberRole).to receive(:all_customizable_permissions).and_return(
      { test_new_ability: { feature_category: 'vulnerability_management' } }
    )
    allow(Gitlab).to receive(:current_milestone).and_return('16.5')
  end

  let(:ability) { 'test_new_ability' }
  let(:config) { { destination_root: destination_root } }
  let(:args) { ['--ability', ability] }

  subject(:run_generator) { described_class.start(args, config) }

  context 'when the ability is not yet defined' do
    let(:ability) { 'non_existing_ability' }

    it 'raises an error' do
      expect { run_generator }.to raise_error(ArgumentError)
    end
  end

  context 'when the ability exists' do
    after do
      FileUtils.rm_rf(destination_root)

      table(:schema_migrations).where(version: migrations.map(&:version)).delete_all

      active_record_base.connection.execute(<<~SQL)
        ALTER TABLE member_roles DROP COLUMN #{ability};
      SQL
    end

    it 'creates the migration file with the right content' do
      run_generator

      migration = migrations.first

      expect(migrations.count).to eq(1)
      expect(migration.name).to eq('AddTestNewAbilityToMemberRoles')
      expect(MemberRole.column_names).not_to include('test_new_ability')

      schema_migrate_up!

      expect(MemberRole.column_names).to include('test_new_ability')
    end
  end

  # We want to execute only the newly generated migrations
  def migrations_paths
    [File.join(destination_root, 'db', 'migrate')]
  end

  def destination_root
    File.expand_path("../tmp", __dir__)
  end

  def schema_migrate_down!
    # no-op
  end
end
