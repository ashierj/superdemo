# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Runners::CreateGoogleCloudProvisioningStepsService, feature_category: :fleet_visibility do
  let_it_be(:project) { create(:project) }
  let_it_be(:runner) { create(:ci_runner, :project, projects: [project]) }
  let_it_be(:current_user) { project.owner }

  let(:google_cloud_project_id) { 'google_project_id' }
  let(:region) { 'us-central1' }
  let(:zone) { 'us-central1-a' }
  let(:machine_type) { 'n2d-standard-2' }
  let(:runner_token) { runner.token }
  let(:params) do
    {
      google_cloud_project_id: google_cloud_project_id,
      region: region,
      zone: zone,
      ephemeral_machine_type: machine_type,
      runner_token: runner_token
    }
  end

  subject(:execute) do
    described_class.new(project: project, current_user: current_user, params: params).execute
  end

  it 'returns an error' do
    expect(execute.status).to eq :error
    expect(execute.reason).to eq :insufficient_permissions
    expect(execute.message).to eq s_('Runners|The user is not allowed to provision a cloud runner')
  end

  context 'with saas-only feature enabled' do
    before do
      stub_saas_features(google_cloud_support: true)
    end

    it 'returns provisioning steps' do
      expect(execute.status).to eq :success

      steps = execute.payload[:provisioning_steps]
      expect(steps).to match([
        {
          instructions: a_string_including("google_project = \"#{google_cloud_project_id}\""),
          language_identifier: 'terraform',
          title: s_('Runners|Save the Terraform script to a file')
        },
        {
          instructions: /gitlab_runner="#{runner_token}"/,
          language_identifier: 'shell',
          title: s_('Runners|Apply the Terraform script')
        }
      ])
    end

    context 'with nil runner token' do
      let(:runner_token) { nil }

      it 'is successful and generates a unique deployment id' do
        expect(execute.status).to eq :success

        steps = execute.payload[:provisioning_steps]
        expect(steps).to match([
          a_hash_including(instructions: /name = "grit-[A-Za-z0-9_\-]{8}"/),
          an_instance_of(Hash)
        ])
      end

      context 'when new deployment name is invalid' do
        it 'returns internal error' do
          expect(Devise).to receive(:friendly_token).with(Ci::Runner::RUNNER_SHORT_SHA_LENGTH).and_return('1234567/')

          expect(execute.status).to eq :error
          expect(execute.reason).to eq :internal_error
          expect(execute.message).to eq s_('Runners|The deployment name is invalid')
        end
      end

      context 'when user does not have permissions to create runner' do
        before do
          allow(Ability).to receive(:allowed?).and_call_original
          allow(Ability).to receive(:allowed?).with(current_user, :create_runner, anything).and_return(false)
        end

        it 'returns an error' do
          expect(execute.status).to eq :error
          expect(execute.reason).to eq :insufficient_permissions
          expect(execute.message).to eq s_('Runners|The user is not allowed to create a runner')
        end
      end
    end

    context 'with invalid runner token' do
      let(:runner_token) { 'invalid-token' }

      it 'returns an error' do
        expect(execute.status).to eq :error
        expect(execute.reason).to eq :invalid_argument
        expect(execute.message).to eq s_('Runners|The runner authentication token is invalid')
      end
    end

    context 'with invalid region name' do
      let(:region) { '" invalid-region "' }

      it 'uses a sanitized value' do
        expect(execute.status).to eq :success

        steps = execute.payload[:provisioning_steps]
        expect(steps).to match([
          a_hash_including(instructions: a_string_including("google_region  = \"__invalid-region__\"")),
          an_instance_of(Hash)
        ])
      end
    end

    context 'with invalid zone name' do
      let(:zone) { '" invalid-zone "' }

      it 'uses a sanitized value' do
        expect(execute.status).to eq :success

        steps = execute.payload[:provisioning_steps]
        expect(steps).to match([
          a_hash_including(instructions: /google_zone += "__invalid-zone__"/),
          an_instance_of(Hash)
        ])
      end
    end

    context 'with invalid machine type name' do
      let(:machine_type) { '" invalid-machine-type "' }

      it 'uses a sanitized value' do
        expect(execute.status).to eq :success

        steps = execute.payload[:provisioning_steps]
        expect(steps).to match([
          a_hash_including(instructions: /machine_type += "__invalid-machine-type__"/),
          an_instance_of(Hash)
        ])
      end
    end

    context 'when user is not authorized' do
      let(:current_user) { create(:user).tap { |user| project.add_developer(user) } }

      it 'returns an error' do
        allow(Ability).to receive(:allowed?).and_call_original
        expect(Ability).to receive(:allowed?).with(current_user, :provision_cloud_runner, project).and_call_original

        expect(execute.status).to eq :error
        expect(execute.reason).to eq :insufficient_permissions
        expect(execute.message).to eq s_('Runners|The user is not allowed to provision a cloud runner')
      end
    end

    context 'when google_cloud_runner_provisioning FF is not enabled' do
      before do
        stub_feature_flags(google_cloud_runner_provisioning: false)
      end

      it 'returns an error' do
        expect(execute.status).to eq :error
        expect(execute.reason).to eq :google_cloud_provisioning_disabled
        expect(execute.message).to eq s_('Runners|Google Cloud provisioning is disabled for this project')
      end
    end
  end
end
