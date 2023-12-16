# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Runners::ExportUsageCsvWorker, :click_house, :enable_admin_mode, feature_category: :fleet_visibility do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }

  let(:worker) { described_class.new }

  describe '#perform' do
    subject(:perform) { worker.perform(current_user.id, runner_type) }

    let(:current_user) { admin }
    let(:runner_type) { 1 }

    before do
      stub_licensed_features(runner_performance_insights: true)
    end

    it 'delegates to Ci::Runners::SendUsageCsvService' do
      expect_next_instance_of(Ci::Runners::SendUsageCsvService,
        { current_user: current_user, runner_type: runner_type }) do |service|
        expect(service).to receive(:execute).and_call_original
      end

      perform

      expect(worker.logging_extras).to eq({
        "extra.ci_runners_export_usage_csv_worker.status" => :success,
        "extra.ci_runners_export_usage_csv_worker.csv_status" => {
          rows_expected: 0, rows_written: 0, truncated: false
        }
      })
    end

    context 'when runner_performance_insights feature is not available' do
      before do
        stub_licensed_features(runner_performance_insights: false)
      end

      let(:runner_type) { nil }

      it 'returns error' do
        perform

        expect(worker.logging_extras).to eq({
          "extra.ci_runners_export_usage_csv_worker.status" => :error,
          "extra.ci_runners_export_usage_csv_worker.message" => 'Insufficient permissions to generate export'
        })
      end
    end
  end
end
