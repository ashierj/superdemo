# frozen_string_literal: true

require "spec_helper"

RSpec.describe RemoteDevelopment::Workspaces::Create::EditorComponentInjector, feature_category: :remote_development do
  include_context 'with remote development shared fixtures'

  let(:agent) { create(:ee_cluster_agent, :with_remote_development_agent_config) }
  let(:input_processed_devfile_name) { 'example.flattened-devfile.yaml' }
  let(:input_processed_devfile) { YAML.safe_load(read_devfile(input_processed_devfile_name)).to_h }
  let(:expected_processed_devfile_name) { 'example.editor-injected-devfile.yaml' }
  let(:expected_processed_devfile) { YAML.safe_load(read_devfile(expected_processed_devfile_name)).to_h }
  let(:value) do
    {
      params: {
        editor: "editor" # NOTE: Currently unused
      },
      processed_devfile: input_processed_devfile,
      volume_mounts: {
        data_volume: {
          path: "/projects"
        }
      }
    }
  end

  subject(:returned_value) do
    described_class.inject(value)
  end

  it "injects the editor injector component" do
    expect(returned_value[:processed_devfile]).to eq(expected_processed_devfile)
  end
end
