# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::FieldEntity do
  let(:request) { EntityRequest.new(integration: integration) }

  subject { described_class.new(field, request: request, integration: integration).as_json }

  before do
    allow(request).to receive(:integration).and_return(integration)
  end

  describe '#as_json' do
    context 'with GitHub integration' do
      let(:integration) { create(:github_integration) }

      context 'with field with type checkbox' do
        let(:field) { integration_field('static_context') }

        it 'exposes correct attributes and casts value to Boolean' do
          expected_hash = {
            type: 'checkbox',
            name: 'static_context',
            title: 'Static status check names (optional)',
            placeholder: nil,
            required: nil,
            choices: nil,
            value: 'true',
            checkbox_label: 'Enable static status check names'
          }

          is_expected.to include(expected_hash)
        end
      end
    end

    context 'with Google Artifact Registry integration' do
      let(:integration) { create(:google_cloud_platform_artifact_registry_integration) }

      context 'with field with type text' do
        let(:field) { integration_field('artifact_registry_project_id') }

        before do
          allow(ApplicationController.helpers).to receive(:sprite_icon).with('external-link').and_return('<svg></svg>')
        end

        it 'exposes correct attributes' do
          expected_hash = {
            section: 'connection',
            type: 'text',
            name: 'artifact_registry_project_id',
            title: 'Google Cloud project ID',
            placeholder: nil,
            label_description: 'Project with the Artifact Registry repository.',
            help: 'To improve security, use a dedicated project for resources, separate from CI/CD and identity ' \
                  'management projects. <a target="_blank" rel="noopener noreferrer" href="' \
                  'https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects">' \
                  'Where’s my project ID? <svg></svg></a>',
            required: true,
            choices: nil,
            value: 'dev-gcp-9abafed1',
            checkbox_label: nil
          }

          is_expected.to include(expected_hash)
        end
      end
    end
  end

  def integration_field(name)
    integration.form_fields.find { |f| f[:name] == name }
  end
end
