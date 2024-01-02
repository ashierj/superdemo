# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20231207132344_remove_issue_documents_based_on_schema_version.rb')

RSpec.describe RemoveIssueDocumentsBasedOnSchemaVersion, :elastic, :sidekiq_inline, feature_category: :global_search do
  include_examples 'migration deletes documents based on schema version' do
    let(:version) { 20231207132344 }
    let(:objects) { create_list(:issue, 3) }
    let(:expected_throttle_delay) { 1.minute }
    let(:expected_batch_size) { 10000 }
  end
end
