# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::Settings::PublicApi, feature_category: :remote_development do
  describe "get_single_setting" do
    context "when passed a valid setting name" do
      it "returns the setting value" do
        expect(RemoteDevelopment::Settings.get_single_setting(:max_hours_before_termination_limit)).to eq(120)
      end
    end

    context "when passed an invalid setting name" do
      it "raises an exception with a descriptive message" do
        expect { RemoteDevelopment::Settings.get_single_setting(:invalid_setting_name) }
          .to raise_error("Unsupported Remote Development setting name: 'invalid_setting_name'")
      end
    end
  end

  describe "get_all_settings" do
    it "returns a Hash containing all settings" do
      expect(RemoteDevelopment::Settings.get_all_settings)
        .to match(hash_including(max_hours_before_termination_limit: 120))
    end
  end
end
