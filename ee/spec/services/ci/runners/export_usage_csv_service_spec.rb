# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Runners::ExportUsageCsvService, feature_category: :fleet_visibility do
  let(:runner_type) { nil }
  let(:from_time) { nil }
  let(:to_time) { nil }
  let(:service) do
    described_class.new(current_user: current_user, runner_type: runner_type, from_time: from_time, to_time: to_time)
  end

  subject(:response) { service.execute }

  shared_examples 'insufficient permissions' do
    it 'returns error due to insufficient permissions' do
      is_expected.to be_error

      expect(response.message).to eq('Insufficient permissions to generate export')
      expect(response.reason).to eq(:insufficient_permissions)
    end

    it 'does not call the auditor' do
      expect(::Gitlab::Audit::Auditor).not_to receive(:audit)
    end
  end

  shared_examples 'a service calling the auditor' do
    it 'calls the auditor' do
      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(a_hash_including(
        additional_details: { runner_type: ::Ci::Runner.runner_types[runner_type],
                              from_time: expected_from_time.utc.strftime('%Y-%m-%d %H:%M:%S'),
                              to_time: expected_to_time.utc.strftime('%Y-%m-%d %H:%M:%S') }.compact,
        name: 'ci_runner_usage_export',
        author: current_user,
        scope: an_instance_of(Gitlab::Audit::InstanceScope),
        target: an_instance_of(Gitlab::Audit::InstanceScope),
        message: 'Generated CI runner usage report'
      ))

      response
    end
  end

  context 'when current_user is not an admin' do
    let_it_be(:current_user) { create(:user) }

    context 'and database is configured', :click_house do
      it_behaves_like 'insufficient permissions'
    end
  end

  context 'when current_user is an admin' do
    let_it_be(:current_user) { create(:admin) }

    context 'when no ClickHouse databases are configured' do
      before do
        allow(ClickHouse::Client.configuration).to receive(:databases).and_return({})
      end

      it 'returns error when ClickHouse database is not configured' do
        is_expected.to be_error

        expect(response.message).to eq('ClickHouse database is not configured')
        expect(response.reason).to eq(:db_not_configured)
      end

      it 'does not call the auditor' do
        expect(::Gitlab::Audit::Auditor).not_to receive(:audit)
      end
    end

    context 'when database is configured', :click_house, :freeze_time do
      include ClickHouseHelpers

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
      end

      let(:expected_header) { "Project ID,Project path,Build count,Total duration (minutes),Total duration\n" }
      let(:expected_from_time) { DateTime.new(2023, 12, 1) }
      let(:expected_to_time) { DateTime.new(2023, 12, 31, 23, 59, 59) }

      before do
        stub_licensed_features(runner_performance_insights: true)
        insert_ci_builds_to_click_house(builds)

        travel_to DateTime.new(2024, 1, 10)
      end

      specify 'should contain 23 builds' do
        expect(ClickHouse::Client.select('SELECT count() FROM ci_finished_builds', :main))
          .to contain_exactly({ 'count()' => 23 })
      end

      context 'when admin mode is disabled' do
        it_behaves_like 'insufficient permissions'
      end

      context 'when admin mode is enabled', :enable_admin_mode do
        it 'exports usage data for all runners for the last complete month', :aggregate_failures do
          expect_next_instance_of(CsvBuilder::SingleBatch, anything, anything) do |csv_builder|
            expect(csv_builder).to receive(:render)
              .with(ExportCsv::BaseService::TARGET_FILESIZE)
              .and_call_original
          end

          expect(response.payload[:csv_data].lines).to eq([
            expected_header,
            "#{builds[21].project_id},#{builds[21].project.full_path},2,130,2 hours and 10 minutes\n",
            "#{builds[0].project_id},#{builds[0].project.full_path},1,14,14 minutes\n",
            "#{builds[1].project_id},#{builds[1].project.full_path},1,14,14 minutes\n",
            "#{builds[2].project_id},#{builds[2].project.full_path},1,14,14 minutes\n",
            "#{builds[3].project_id},#{builds[3].project.full_path},1,14,14 minutes\n",
            "#{builds.last.project_id},#{builds.last.project.full_path},1,7,7 minutes\n"
          ])

          expect(response.payload[:status]).to eq({ rows_expected: 6, rows_written: 6, truncated: false })
        end

        it_behaves_like 'a service calling the auditor'

        context 'when runner_performance_insights feature is not available' do
          before do
            stub_licensed_features(runner_performance_insights: false)
          end

          it_behaves_like 'insufficient permissions'
        end

        context 'with group_type runner_type argument specified' do
          let(:runner_type) { :group_type }

          it 'exports usage data for runners of specified type' do
            expect(response.payload[:csv_data].lines).to eq([
              expected_header,
              "#{builds[21].project_id},#{builds[21].project.full_path},1,120,2 hours\n"
            ])

            expect(response.payload[:status]).to eq({ rows_expected: 1, rows_written: 1, truncated: false })
          end

          it_behaves_like 'a service calling the auditor'
        end

        context 'with project_type runner_type argument specified' do
          let(:runner_type) { :project_type }

          it 'exports usage data for runners of specified type' do
            expect(response.payload[:csv_data].lines).to contain_exactly(expected_header)
            expect(response.payload[:status]).to eq({ rows_expected: 0, rows_written: 0, truncated: false })
          end
        end

        context 'with from_time argument specified' do
          context 'and from_time is Jan 2024' do
            let(:from_time) { DateTime.new(2024, 1, 1) }
            let(:expected_from_time) { from_time }
            let(:expected_to_time) { from_time.end_of_month }

            it 'exports usage data for runners which finished builds before date' do
              expect(response.payload[:status]).to eq({ rows_expected: 16, rows_written: 16, truncated: false })
            end

            it_behaves_like 'a service calling the auditor'
          end

          context 'and from_time is Feb 2024' do
            let(:from_time) { DateTime.new(2024, 2, 1) }
            let(:expected_from_time) { from_time }
            let(:expected_to_time) { from_time.end_of_month }

            it 'exports usage data for runners which finished builds before date' do
              expect(response.payload[:status]).to eq({ rows_expected: 0, rows_written: 0, truncated: false })
            end
          end
        end

        context 'with to_time argument specified' do
          context 'and to_time is Dec 2023' do
            let(:to_time) { DateTime.new(2023, 12, 31, 23, 0, 0) }
            let(:expected_from_time) { DateTime.new(2023, 11, 1) }
            let(:expected_to_time) { to_time }

            before do
              travel_to DateTime.new(2023, 12, 31, 23, 59, 59)
            end

            it 'exports usage data for runners which finished builds after date' do
              expect(response.payload[:status]).to eq({ rows_expected: 6, rows_written: 6, truncated: false })
            end

            it_behaves_like 'a service calling the auditor'
          end

          context 'and to_time is Jan 2024' do
            let(:to_time) { DateTime.new(2024, 1, 31) }
            let(:expected_from_time) { DateTime.new(2024, 1, 1) }
            let(:expected_to_time) { to_time }

            before do
              travel_to DateTime.new(2024, 2, 10)
            end

            it 'exports usage data for runners which finished builds after date' do
              expect(response.payload[:status]).to eq({ rows_expected: 16, rows_written: 16, truncated: false })
            end

            it_behaves_like 'a service calling the auditor'
          end
        end
      end
    end
  end

  def create_build(runner, project, created_at, duration = 14.minutes)
    started_at = created_at + 6.minutes

    build(:ci_build,
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
