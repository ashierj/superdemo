# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'RunnersExportUsage', :click_house, :enable_admin_mode, :sidekiq_inline, :freeze_time,
  feature_category: :fleet_visibility do
  include GraphqlHelpers
  include ClickHouseHelpers

  let_it_be(:current_user) { create(:admin) }
  let_it_be(:instance_runner) { create(:ci_runner, :instance) }
  let_it_be(:group_runner) { create(:ci_runner, :group) }
  let_it_be(:start_time) { 1.month.ago }
  let_it_be(:build1) do
    build(:ci_build, :success, created_at: start_time, queued_at: start_time, started_at: start_time,
      finished_at: start_time + 10.minutes, runner: instance_runner)
  end

  let_it_be(:build2) do
    build(:ci_build, :success, created_at: start_time, queued_at: start_time, started_at: start_time,
      finished_at: start_time + 10.minutes, runner: group_runner)
  end

  let(:runner_type) { 'GROUP_TYPE' }
  let(:mutation) do
    graphql_mutation(:runners_export_usage, type: runner_type) do
      <<~QL
        errors
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:runners_export_usage) }

  subject(:post_response) { post_graphql_mutation(mutation, current_user: current_user) }

  before do
    stub_licensed_features(runner_performance_insights: true)
    travel_to DateTime.new(2023, 12, 14)

    insert_ci_builds_to_click_house([build1, build2])
  end

  it 'sends email with report' do
    expect(Notify).to receive(:runner_usage_by_project_csv_email)
      .with(
        user: current_user, from_time: DateTime.new(2023, 11, 1), to_time: DateTime.new(2023, 11, 1).end_of_month,
        csv_data: anything, export_status: anything
      ) do |args|
        expect(args.dig(:export_status, :rows_written)).to eq 1

        parsed_csv = CSV.parse(args[:csv_data], headers: true)
        expect(parsed_csv[0]['Project ID']).to eq build2.project.id.to_s

        instance_double(ActionMailer::MessageDelivery, deliver_now: true)
      end

    post_response
    expect_graphql_errors_to_be_empty
  end

  context 'when feature is not available' do
    before do
      stub_licensed_features(runner_performance_insights: false)
    end

    it 'returns an error' do
      post_response

      expect(graphql_errors)
        .to include(a_hash_including('message' => "The resource that you are attempting to access does " \
                                                  "not exist or you don't have permission to perform this action"))
    end
  end
end
