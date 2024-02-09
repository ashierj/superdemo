# frozen_string_literal: true

require "spec_helper"

RSpec.describe RemoteDevelopment::Workspaces::Create::ToolsComponentInjector, feature_category: :remote_development do
  include_context 'with remote development shared fixtures'

  let(:agent) { create(:ee_cluster_agent, :with_remote_development_agent_config) }
  let(:input_processed_devfile_name) { 'example.flattened-devfile.yaml' }
  let(:input_processed_devfile) { YAML.safe_load(read_devfile(input_processed_devfile_name)).to_h }
  let(:expected_processed_devfile_name) { 'example.tools-injected-devfile.yaml' }
  let(:expected_processed_devfile) { YAML.safe_load(read_devfile(expected_processed_devfile_name)).to_h }
  let(:value) do
    {
      params: {
        agent: agent
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

  it 'injects the tools injector component' do
    expect(returned_value[:processed_devfile]).to eq(expected_processed_devfile)
  end

  context "when allow_extensions_marketplace_in_workspace is disabled" do
    let(:expected_processed_devfile_name) { 'example.tools-injected-marketplace-disabled-devfile.yaml' }

    before do
      stub_feature_flags(allow_extensions_marketplace_in_workspace: false)
    end

    it 'injects the tools injector component' do
      expect(returned_value[:processed_devfile]).to eq(expected_processed_devfile)
    end
  end

  context "when devfile attribute gl/use-vscode-1-81 is false" do
    let(:expected_processed_devfile_name) { 'example.tools-injected-vscode-1-85-devfile.yaml' }

    before do
      tools_component = input_processed_devfile['components'].find { |c| c.dig('attributes', 'gl/inject-editor') }
      tools_component['attributes']['gl/use-vscode-1-81'] = false
    end

    it 'injects the tools injector component' do
      expect(returned_value[:processed_devfile]).to eq(expected_processed_devfile)
    end
  end
end
