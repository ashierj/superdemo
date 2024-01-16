# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Runners::GenerateUsageCsvService, :enable_admin_mode, :click_house,
  feature_category: :fleet_visibility do
  include ClickHouseHelpers

  let_it_be(:current_user) { build_stubbed(:admin) }
  let_it_be(:instance_runner) { create(:ci_runner, :instance, :with_runner_manager) }
  let_it_be(:group) { create(:group) }
  let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group]) }
  let_it_be(:builds) do
    starting_time = DateTime.new(2023, 12, 31, 21, 0, 0)

    builds = Array.new(5) do |i|
      project = create(:project, group: group)
      create_build(instance_runner, project, starting_time + (50.minutes * i),
        (14 + i).minutes, Ci::HasStatus::COMPLETED_STATUSES[i % Ci::HasStatus::COMPLETED_STATUSES.size])
    end

    project = create(:project, group: group)
    builds << create_build(group_runner, project, starting_time, 20.hours, :failed)
    builds << create_build(instance_runner, project, starting_time, 10.minutes, :failed)
    builds << create_build(instance_runner, project, starting_time, 7.minutes)
    builds
  end

  let(:runner_type) { :instance_type }
  let(:from_date) { Date.new(2023, 12, 1) }
  let(:to_date) { Date.new(2023, 12, 31) }
  let(:max_project_count) { 2 }
  let(:response_status) { response.payload[:status] }
  let(:response_csv_lines) { response.payload[:csv_data].lines }
  let(:service) do
    described_class.new(current_user, runner_type: runner_type, from_date: from_date, to_date: to_date,
      max_project_count: max_project_count)
  end

  let(:expected_header) do
    "Project ID,Project path,Status,Runner type,Build count,Total duration (minutes),Total duration\n"
  end

  subject(:response) { service.execute }

  before do
    stub_licensed_features(runner_performance_insights: true)

    insert_ci_builds_to_click_house(builds)
  end

  context 'when GetUsageByProjectService returns error' do
    let_it_be(:current_user) { create(:user) }

    it 'also returns error' do
      is_expected.to be_error

      expect(response.message).to eq('Insufficient permissions')
      expect(response.reason).to eq(:insufficient_permissions)
    end
  end

  it 'exports usage data for all runners for the last complete month' do
    expect_next_instance_of(CsvBuilder::SingleBatch, anything, anything) do |csv_builder|
      expect(csv_builder).to receive(:render)
        .with(ExportCsv::BaseService::TARGET_FILESIZE)
        .and_call_original
    end

    expect(response_csv_lines).to eq([
      expected_header,
      "#{project_id_and_full_path(builds[3])},skipped,instance_type,1,17,17 minutes\n",
      "#{project_id_and_full_path(builds.last)},failed,instance_type,1,10,10 minutes\n",
      "#{project_id_and_full_path(builds.last)},success,instance_type,1,7,7 minutes\n",
      ",<Other projects>,canceled,instance_type,1,16,16 minutes\n",
      ",<Other projects>,failed,instance_type,1,15,15 minutes\n",
      ",<Other projects>,success,instance_type,1,14,14 minutes\n"
    ])

    expect(response_status).to eq({
      projects_expected: max_project_count, projects_written: 2, rows_expected: 6, rows_written: 6, truncated: false
    })
  end

  def create_build(runner, project, created_at, duration = 14.minutes, status = :success)
    started_at = created_at + 6.minutes

    build_stubbed(:ci_build,
      status,
      created_at: created_at,
      queued_at: created_at,
      started_at: started_at,
      finished_at: started_at + duration,
      project: project,
      runner: runner,
      runner_manager: runner.runner_managers.first)
  end

  def project_id_and_full_path(build)
    [build.project_id, build.project.full_path].join(',')
  end
end
