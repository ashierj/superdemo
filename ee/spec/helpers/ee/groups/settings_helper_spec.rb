# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Groups::SettingsHelper do
  describe '.unique_project_download_limit_settings_data', feature_category: :insider_threat do
    let(:namespace_settings) do
      build(:namespace_settings, unique_project_download_limit: 1,
        unique_project_download_limit_interval_in_seconds: 2,
        unique_project_download_limit_allowlist: %w[username1 username2],
        unique_project_download_limit_alertlist: [3, 4],
        auto_ban_user_on_excessive_projects_download: true)
    end

    let(:group) { build(:group, namespace_settings: namespace_settings) }

    before do
      helper.instance_variable_set(:@group, group)
    end

    subject { helper.unique_project_download_limit_settings_data }

    it 'returns the expected data' do
      is_expected.to eq({ group_full_path: group.full_path,
                          max_number_of_repository_downloads: 1,
                          max_number_of_repository_downloads_within_time_period: 2,
                          git_rate_limit_users_allowlist: %w[username1 username2],
                          git_rate_limit_users_alertlist: [3, 4],
                          auto_ban_user_on_excessive_projects_download: 'true' })
    end
  end
end
