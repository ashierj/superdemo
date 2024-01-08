# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20231213182444_remove_epics_based_on_schema_version.rb')

RSpec.describe RemoveEpicsBasedOnSchemaVersion, :elastic, :sidekiq_inline, feature_category: :global_search do
  include_examples 'migration deletes documents based on schema version' do
    let(:version) { 20231213182444 }
    let(:objects) { create_list(:epic, 3) }
    let(:expected_throttle_delay) { 3.minutes }
    let(:expected_batch_size) { 5000 }
  end
end
