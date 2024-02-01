# frozen_string_literal: true

require "spec_helper"

RSpec.describe RemoteDevelopment::Workspaces::Create::ProjectClonerComponentInjector, feature_category: :remote_development do
  include_context 'with remote development shared fixtures'

  let_it_be(:group) { create(:group, name: "test-group") }
  let_it_be(:project) do
    create(:project, :in_group, :repository, path: "test-project", namespace: group)
  end

  let(:input_processed_devfile_name) { 'example.editor-injected-devfile.yaml' }
  let(:input_processed_devfile) { YAML.safe_load(read_devfile(input_processed_devfile_name)).to_h }
  let(:expected_processed_devfile_name) { 'example.project-cloner-injected-devfile.yaml' }
  let(:expected_processed_devfile) { YAML.safe_load(read_devfile(expected_processed_devfile_name)).to_h }
  let(:component_name) { "gl-cloner-injector" }
  let(:value) do
    {
      params: {
        project: project
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

  it "injects the project cloner component" do
    expect(returned_value[:processed_devfile]).to eq(expected_processed_devfile)
  end
end
