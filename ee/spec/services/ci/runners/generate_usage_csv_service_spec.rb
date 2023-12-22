# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Runners::GenerateUsageCsvService, :enable_admin_mode, :click_house, :freeze_time,
  feature_category: :fleet_visibility do
  include ClickHouseHelpers

  let_it_be(:current_user) { build_stubbed(:admin) }
  let_it_be(:instance_runner) { create(:ci_runner, :instance, :with_runner_manager) }
  let_it_be(:group) { create(:group) }
  let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group]) }
  let_it_be(:builds) do
    starting_time = DateTime.new(2023, 12, 31, 21, 0, 0)

    builds = Array.new(20) do |i|
      project = create(:project, group: group)
      create_build(instance_runner, project, starting_time + (50.minutes * i))
    end

    project = create(:project, group: group)
    builds << create_build(group_runner, project, starting_time, 2.hours)
    builds << create_build(instance_runner, project, starting_time, 10.minutes)
    builds << create_build(instance_runner, create(:project, group: group), starting_time, 7.minutes)
    builds
  end

  let(:runner_type) { nil }
  let(:from_date) { Date.new(2023, 12, 1) }
  let(:to_date) { Date.new(2023, 12, 31) }
  let(:max_project_count) { 50 }
  let(:response_status) { response.payload[:status] }
  let(:response_csv_lines) { response.payload[:csv_data].lines }
  let(:service) do
    described_class.new(current_user: current_user, runner_type: runner_type, from_date: from_date, to_date: to_date,
      max_project_count: max_project_count)
  end

  let(:expected_header) { "Project ID,Project path,Build count,Total duration (minutes),Total duration\n" }

  subject(:response) { service.execute }

  before do
    stub_licensed_features(runner_performance_insights: true)

    insert_ci_builds_to_click_house(builds)

    travel_to DateTime.new(2024, 1, 10)
  end

  context 'when current_user is not an admin' do
    let_it_be(:current_user) { create(:user) }

    it 'returns error due to insufficient permissions' do
      is_expected.to be_error

      expect(response.message).to eq('Insufficient permissions to generate export')
      expect(response.reason).to eq(:insufficient_permissions)
    end
  end

  context 'when runner_performance_insights feature is not available' do
    before do
      stub_licensed_features(runner_performance_insights: false)
    end

    it 'returns error due to insufficient permissions' do
      is_expected.to be_error

      expect(response.message).to eq('Insufficient permissions to generate export')
      expect(response.reason).to eq(:insufficient_permissions)
    end
  end

  context 'when no ClickHouse databases are configured' do
    before do
      allow(ClickHouse::Client).to receive(:database_configured?).and_return(false)
    end

    it 'returns error' do
      is_expected.to be_error

      expect(response.message).to eq('ClickHouse database is not configured')
      expect(response.reason).to eq(:db_not_configured)
    end
  end

  context 'when ClickHouse response is a failure' do
    before do
      allow(ClickHouse::Client).to receive(:select).and_raise(::ClickHouse::Client::DatabaseError)
    end

    it 'returns error' do
      expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
        .with(an_instance_of(ClickHouse::Client::DatabaseError))

      is_expected.to be_error

      expect(response.message).to eq('Failed to generate export')
      expect(response.reason).to eq(:clickhouse_error)
    end
  end

  it 'contains 23 builds in source ci_finished_builds table' do
    expect(ClickHouse::Client.select('SELECT count() FROM ci_finished_builds', :main))
      .to contain_exactly({ 'count()' => 23 })
  end

  it 'exports usage data for all runners for the last complete month', :aggregate_failures do
    expect_next_instance_of(CsvBuilder::SingleBatch, anything, anything) do |csv_builder|
      expect(csv_builder).to receive(:render)
        .with(ExportCsv::BaseService::TARGET_FILESIZE)
        .and_call_original
    end

    expect(response_csv_lines).to eq([
      expected_header,
      "#{builds[21].project_id},#{builds[21].project.full_path},2,130,2 hours and 10 minutes\n",
      "#{builds[0].project_id},#{builds[0].project.full_path},1,14,14 minutes\n",
      "#{builds[1].project_id},#{builds[1].project.full_path},1,14,14 minutes\n",
      "#{builds[2].project_id},#{builds[2].project.full_path},1,14,14 minutes\n",
      "#{builds[3].project_id},#{builds[3].project.full_path},1,14,14 minutes\n",
      "#{builds.last.project_id},#{builds.last.project.full_path},1,7,7 minutes\n"
    ])

    expect(response_status).to eq({ rows_expected: 6, rows_written: 6, truncated: false })
  end

  context "when max_project_count doesn't fit all projects" do
    let(:max_project_count) { 2 }

    it 'exports usage data for the 2 top-K projects plus aggregate for other projects', :aggregate_failures do
      expect(response_csv_lines).to eq([
        expected_header,
        "#{builds[21].project_id},#{builds[21].project.full_path},2,130,2 hours and 10 minutes\n",
        "#{builds[0].project_id},#{builds[0].project.full_path},1,14,14 minutes\n",
        ",<Other projects>,4,49,49 minutes\n"
      ])

      expect(response_status).to eq({ rows_expected: 2, rows_written: 2, truncated: false })
    end
  end

  context 'with group_type runner_type argument specified' do
    let(:runner_type) { :group_type }

    it 'exports usage data for runners of specified type' do
      expect(response_csv_lines).to eq([
        expected_header,
        "#{builds[21].project_id},#{builds[21].project.full_path},1,120,2 hours\n"
      ])

      expect(response_status).to eq({ rows_expected: 1, rows_written: 1, truncated: false })
    end
  end

  context 'with project_type runner_type argument specified' do
    let(:runner_type) { :project_type }

    it 'exports usage data for runners of specified type' do
      expect(response_csv_lines).to contain_exactly(expected_header)
      expect(response_status).to eq({ rows_expected: 0, rows_written: 0, truncated: false })
    end
  end

  context 'when time window is current month' do
    let(:from_date) { Date.new(2024, 1, 1) }
    let(:to_date) { Date.new(2024, 1, 31) }

    it 'exports usage data for runners which finished builds before date' do
      expect(response_status).to eq({ rows_expected: 16, rows_written: 16, truncated: false })
    end
  end

  context 'when time window is next month' do
    let(:from_date) { Date.new(2024, 2, 1) }
    let(:to_date) { Date.new(2024, 2, 29) }

    it 'exports usage data for runners which finished builds before date' do
      expect(response_status).to eq({ rows_expected: 0, rows_written: 0, truncated: false })
    end
  end

  context 'when to_date is an hour ago, almost at the end of the year' do
    let(:from_date) { Date.new(2023, 11, 1) }
    let(:to_date) { Date.new(2023, 12, 31) }

    before do
      travel_to DateTime.new(2023, 12, 31, 23, 59, 59)
    end

    it 'exports usage data for runners which finished builds after date' do
      expect(response_status).to eq({ rows_expected: 6, rows_written: 6, truncated: false })
    end
  end

  def create_build(runner, project, created_at, duration = 14.minutes)
    started_at = created_at + 6.minutes

    build_stubbed(:ci_build,
      :success,
      created_at: created_at,
      queued_at: created_at,
      started_at: started_at,
      finished_at: started_at + duration,
      project: project,
      runner: runner,
      runner_manager: runner.runner_managers.first)
  end
end
