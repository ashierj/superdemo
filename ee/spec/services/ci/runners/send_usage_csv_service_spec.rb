# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Runners::SendUsageCsvService, :enable_admin_mode, :click_house, :freeze_time,
  feature_category: :fleet_visibility do
  include ClickHouseHelpers

  let_it_be(:current_user) { create(:admin) }
  let_it_be(:instance_runner) { create(:ci_runner, :instance, :with_runner_manager) }

  let(:from_time) { 1.month.ago }
  let(:to_time) { DateTime.current }
  let(:service) do
    described_class.new(current_user: current_user, runner_type: :instance_type, from_time: from_time, to_time: to_time)
  end

  subject(:response) { service.execute }

  before do
    stub_licensed_features(runner_performance_insights: true)
    started_at = created_at = 1.hour.ago
    project = build(:project)
    build = build_stubbed(:ci_build, :success, created_at: created_at, queued_at: created_at, started_at: started_at,
      finished_at: started_at + 10.minutes, project: project, runner: instance_runner,
      runner_manager: instance_runner.runner_managers.first)
    insert_ci_builds_to_click_house([build])
  end

  it 'sends the csv by email' do
    expect_next_instance_of(Ci::Runners::GenerateUsageCsvService) do |service|
      expect(service).to receive(:execute).and_call_original
    end

    expected_status = { rows_expected: 1, rows_written: 1, truncated: false }
    expect(Notify).to receive(:runner_usage_by_project_csv_email)
      .with(user: current_user, from_time: from_time, to_time: to_time, csv_data: anything,
        export_status: expected_status)
      .and_return(instance_double(ActionMailer::MessageDelivery, deliver_now: true))

    expect(response).to be_success
    expect(response.payload).to eq({ status: expected_status })
  end

  context 'when report fails to be generated' do
    before do
      allow_next_instance_of(Ci::Runners::GenerateUsageCsvService) do |service|
        allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'Generation failed'))
      end
    end

    it 'returns error from GenerateUsageCsvService' do
      expect(Notify).not_to receive(:runner_usage_by_project_csv_email)

      expect(response).to be_error
      expect(response.message).to eq('Generation failed')
    end
  end
end
