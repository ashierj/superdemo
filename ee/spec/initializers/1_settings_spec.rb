# frozen_string_literal: true

require 'spec_helper'

RSpec.describe '1_settings' do
  context 'cron jobs' do
    subject(:cron_jobs) { Settings.cron_jobs }

    context 'sync_seat_link_worker cron job' do
      # explicit use of UTC for self-managed instances to ensure job runs after a Customers Portal job
      it 'schedules the job at the correct time' do
        expect(cron_jobs.dig('sync_seat_link_worker', 'cron')).to match(/[1-5]{0,1}[0-9]{1,2} [34] \* \* \* UTC/)
      end
    end

    context 'sync_service_token_worker cron job' do
      # explicit use of UTC for self-managed instances to ensure job runs after a SyncSeatLink job
      it 'schedules the job at the correct time' do
        expect(cron_jobs.dig('sync_service_token_worker', 'cron')).to match(/[1-5]{0,1}[0-9]{1,2} [56] \* \* \* UTC/)
      end
    end

    context 'gitlab.com', :saas do
      let(:dot_com_cron_jobs) do
        %w[
          disable_legacy_open_source_license_for_inactive_projects
          notify_seats_exceeded_batch_worker
          gitlab_subscriptions_schedule_refresh_seats_worker
        ]
      end

      it 'assigns .com only settings' do
        load_settings

        expect(cron_jobs.keys).to include(*dot_com_cron_jobs)
      end
    end
  end

  describe 'cloud_connector' do
    subject(:cloud_connector_base_url) { Settings.cloud_connector.base_url }

    context 'when const CLOUD_CONNECTOR_BASE_URL is set' do
      before do
        stub_env("CLOUD_CONNECTOR_BASE_URL", 'https://www.cloud.example.com')
        load_settings
      end

      it { is_expected.to eq('https://www.cloud.example.com') }
    end

    context 'when const CLOUD_CONNECTOR_BASE_URL is not set' do
      before do
        load_settings
      end

      it { is_expected.to eq('https://cloud.gitlab.com') }
    end
  end

  def load_settings
    load Rails.root.join('config/initializers/1_settings.rb')
  end
end
