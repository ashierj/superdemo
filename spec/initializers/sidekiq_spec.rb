# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'sidekiq', feature_category: :build do
  describe 'enable_reliable_fetch?' do
    subject { enable_reliable_fetch? }

    context 'when gitlab_sidekiq_reliable_fetcher is enabled' do
      before do
        stub_feature_flags(gitlab_sidekiq_reliable_fetcher: true)
      end

      it { is_expected.to be_truthy }
    end

    context 'when gitlab_sidekiq_reliable_fetcher is disabled' do
      before do
        stub_feature_flags(gitlab_sidekiq_reliable_fetcher: false)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe 'enable_semi_reliable_fetch_mode?' do
    subject { enable_semi_reliable_fetch_mode? }

    context 'when gitlab_sidekiq_enable_semi_reliable_fetcher is enabled' do
      before do
        stub_feature_flags(gitlab_sidekiq_enable_semi_reliable_fetcher: true)
      end

      it { is_expected.to be_truthy }
    end

    context 'when gitlab_sidekiq_enable_semi_reliable_fetcher is disabled' do
      before do
        stub_feature_flags(gitlab_sidekiq_enable_semi_reliable_fetcher: false)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe 'load_cron_jobs!' do
    subject { load_cron_jobs! }

    let(:cron_for_service_ping) { '4 7 * * 4' }

    let(:cron_jobs_settings) do
      {
        'gitlab_service_ping_worker' => {
          'cron' => nil,
          'job_class' => 'GitlabServicePingWorker'
        },
        'import_export_project_cleanup_worker' => {
          'cron' => '0 * * * *',
          'job_class' => 'ImportExportProjectCleanupWorker'
        },
        "invalid_worker" => {
          'cron' => '0 * * * *'
        }
      }
    end

    let(:cron_jobs_hash) do
      {
        'gitlab_service_ping_worker' => {
          'cron' => cron_for_service_ping,
          'class' => 'GitlabServicePingWorker'
        },
        'import_export_project_cleanup_worker' => {
          'cron' => '0 * * * *',
          'class' => 'ImportExportProjectCleanupWorker'
        }
      }
    end

    around do |example|
      Gitlab::SidekiqConfig.clear_memoization(:cron_jobs)
      original_settings = Gitlab.config['cron_jobs']
      Gitlab.config['cron_jobs'] = cron_jobs_settings

      example.run

      Gitlab::SidekiqConfig.clear_memoization(:cron_jobs)
      Gitlab.config['cron_jobs'] = original_settings
    end

    it 'loads the cron jobs into sidekiq-cron' do
      allow(Settings).to receive(:cron_for_service_ping).and_return(cron_for_service_ping)

      expect(Sidekiq::Cron::Job).to receive(:load_from_hash!).with(cron_jobs_hash)

      if Gitlab.ee?
        expect(Gitlab::Mirror).to receive(:configure_cron_job!)
        expect(Gitlab::Geo).to receive(:configure_cron_jobs!)
      end

      subject
    end
  end
end
