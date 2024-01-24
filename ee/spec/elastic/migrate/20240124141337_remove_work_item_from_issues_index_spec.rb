# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20240124141337_remove_work_item_from_issues_index.rb')

RSpec.describe RemoveWorkItemFromIssuesIndex, :elastic, :sidekiq_inline, feature_category: :global_search do
  include_examples 'migration deletes documents based on schema version' do
    let(:version) { 20240124141337 }
    let(:objects) { create_list(:work_item, 3) }
    let(:expected_throttle_delay) { 1.minute }
    let(:expected_batch_size) { 10000 }
  end
end
