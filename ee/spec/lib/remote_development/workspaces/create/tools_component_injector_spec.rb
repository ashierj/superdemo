# frozen_string_literal: true

require "spec_helper"

RSpec.describe RemoteDevelopment::Workspaces::Create::ToolsComponentInjector, feature_category: :remote_development do
  include_context 'with remote development shared fixtures'

  let(:agent) { create(:ee_cluster_agent, :with_remote_development_agent_config) }
  let(:flattened_devfile_name) { 'example.flattened-devfile.yaml' }
  let(:input_processed_devfile) { YAML.safe_load(read_devfile(flattened_devfile_name)).to_h }
  let(:processed_devfile_name) { 'example.processed-devfile.yaml' }
  let(:expected_processed_devfile) { YAML.safe_load(read_devfile(processed_devfile_name)).to_h }
  let(:volume_name) { 'gl-workspace-data' }
  let(:value) do
    {
      params: {
        agent: agent
      },
      processed_devfile: input_processed_devfile,
      volume_mounts: {
        data_volume: {
          name: volume_name,
          path: "/projects"
        }
      }
    }
  end

  subject(:returned_value) do
    described_class.inject(value)
  end

  shared_examples 'successful injection of tools components' do
    it 'injects the tools injector component' do
      components = returned_value.dig(:processed_devfile, 'components')
      tools_component = components.find { |c| c.dig('attributes', 'gl/inject-editor') }
      tools_injector_component = components.find { |c| c.fetch('name') == 'gl-tools-injector' }
      relevant_components = [tools_component, tools_injector_component]
      relevant_components_name = relevant_components.map { |c| c.fetch('name') }
      processed_devfile_components = expected_processed_devfile.fetch('components')
      expected_relevant_components = processed_devfile_components.select do |component|
        relevant_components_name.include? component.fetch('name')
      end
      expect(relevant_components).to eq(expected_relevant_components)
    end
  end

  it_behaves_like 'successful injection of tools components'

  context "when allow_extensions_marketplace_in_workspace is disabled" do
    let(:processed_devfile_name) { 'example.processed-marketplace-disabled-devfile.yaml' }

    before do
      stub_feature_flags(allow_extensions_marketplace_in_workspace: false)
    end

    it_behaves_like 'successful injection of tools components'
  end
end
