# frozen_string_literal: true

require_relative "../fast_spec_helper"

RSpec.describe RemoteDevelopment::Settings::EnvVarReader, feature_category: :remote_development do
  include ResultMatchers

  let(:default_setting_value) { 42 }
  let(:setting_type) { Integer }
  let(:value) do
    {
      settings: {
        the_setting: default_setting_value
      },
      setting_types: {
        the_setting: setting_type
      }
    }
  end

  subject(:result) do
    described_class.read(value)
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with(env_var_name) { env_var_value }
  end

  context "when an ENV var overrides a default setting" do
    let(:env_var_name) { "GITLAB_REMOTE_DEVELOPMENT_THE_SETTING" }

    context "when setting_type is String" do
      let(:env_var_value) { "a string" }
      let(:setting_type) { String }

      it "uses the string value of the overridden ENV var value" do
        expect(result).to eq(Result.ok(
          {
            settings: { the_setting: env_var_value },
            setting_types: { the_setting: setting_type }
          }
        ))
      end
    end

    context "when setting_type is Integer" do
      let(:env_var_value) { "999" }
      let(:setting_type) { Integer }

      it "uses the casted type of the overridden ENV var value" do
        expect(result).to eq(Result.ok(
          {
            settings: { the_setting: env_var_value.to_i },
            setting_types: { the_setting: setting_type }
          }
        ))
      end
    end
  end

  context "when no ENV var overrides a default setting" do
    let(:env_var_name) { "GITLAB_REMOTE_DEVELOPMENT_NON_MATCHING_SETTING" }
    let(:env_var_value) { "0" }

    it "uses the default setting value which was passed" do
      expect(result).to eq(Result.ok(
        {
          settings: { the_setting: default_setting_value },
          setting_types: { the_setting: setting_type }
        }
      ))
    end
  end

  context "when an ENV matches the pattern but there is no default setting value defined" do
    let(:env_var_name) { "GITLAB_REMOTE_DEVELOPMENT_NONEXISTENT_SETTING" }
    let(:env_var_value) { "maybe some old deprecated setting, doesn't matter, it's ignored" }

    it "ignores the ENV var" do
      expect(result).to eq(Result.ok(
        {
          settings: { the_setting: default_setting_value },
          setting_types: { the_setting: setting_type }
        }
      ))
    end
  end

  context "when ENV var contains an incorrect type" do
    let(:env_var_name) { "GITLAB_REMOTE_DEVELOPMENT_THE_SETTING" }
    let(:env_var_value) { "not an Integer type" }

    it "returns an err Result containing a settings environment variable read failed message with details" do
      expect(result).to be_err_result(
        RemoteDevelopment::Messages::SettingsEnvironmentVariableReadFailed.new(
          details: "ENV var '#{env_var_name}' value could not be cast to #{setting_type} type."
        )
      )
    end
  end

  context "when setting_type is an unsupported type" do
    let(:env_var_name) { "GITLAB_REMOTE_DEVELOPMENT_THE_SETTING" }
    let(:env_var_value) { "42" }
    let(:setting_type) { Float }

    it "returns an err Result containing a settings environment variable read failed message with details" do
      expect(result).to be_err_result(
        RemoteDevelopment::Messages::SettingsEnvironmentVariableReadFailed.new(
          details: "Unsupported Remote Development setting type: #{setting_type}"
        )
      )
    end
  end
end
