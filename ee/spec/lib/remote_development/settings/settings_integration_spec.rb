# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::RemoteDevelopment::Settings, feature_category: :remote_development do # rubocop:disable RSpec/FilePath -- Not sure why this is being flagged
  subject(:settings_module) do
    described_class
  end

  context "when there is no override" do
    before do
      # Ensure the test doesn't fail if the setting's env var happens to be set in current environment
      stub_env("GITLAB_REMOTE_DEVELOPMENT_MAX_HOURS_BEFORE_TERMINATION_LIMIT", nil)
    end

    it "uses default value" do
      expect(settings_module.get_single_setting(:max_hours_before_termination_limit)).to eq(120)
      expect(settings_module.get_single_setting(:default_branch_name)).to be_nil
    end
  end

  context "when there is an env var override" do
    before do
      stub_env("GITLAB_REMOTE_DEVELOPMENT_MAX_HOURS_BEFORE_TERMINATION_LIMIT", "42")
    end

    it "uses the env var override value and casts it" do
      expect(settings_module.get_single_setting(:max_hours_before_termination_limit)).to eq(42)
    end
  end

  context "when there is and ENV var override and also a ::Gitlab::CurrentSettings override" do
    let(:override_value_from_env) { "value_from_env" }
    let(:override_value_from_current_settings) { "value_from_current_settings" }

    before do
      stub_env("GITLAB_REMOTE_DEVELOPMENT_DEFAULT_BRANCH_NAME", override_value_from_env)

      create(:application_setting)
      stub_application_setting(default_branch_name: override_value_from_current_settings)
    end

    it "uses the ENV var value and not the CurrentSettings value" do
      # fixture sanity check
      expect(Gitlab::CurrentSettings.default_branch_name).to eq(override_value_from_current_settings)

      expect(settings_module.get_single_setting(:default_branch_name)).to eq(override_value_from_env)
    end
  end
end
