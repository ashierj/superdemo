# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ProvisionGoogleCloudRunner', feature_category: :fleet_visibility do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:runner) { create(:ci_runner, :project, projects: [project]) }
  let_it_be(:user) { project.owner }

  let(:google_cloud_project_id) { 'google_project_id' }
  let(:region) { 'us-central1' }
  let(:zone) { 'us-central1-a' }
  let(:machine_type) { 'n2d-standard-2' }
  let(:runner_token) { runner.token }
  let(:dry_run) { true }
  let(:mutation_args) do
    {
      dry_run: dry_run,
      project_path: project.full_path,
      provisioning_project_id: google_cloud_project_id,
      provisioning_region: region,
      provisioning_zone: zone,
      provisioning_machine_type: machine_type,
      runner_token: runner_token
    }
  end

  let(:mutation) do
    graphql_mutation(:provision_google_cloud_runner, mutation_args) do
      <<~QL
        provisioningSteps {
          title
          languageIdentifier
          instructions
        }
        errors
      QL
    end
  end

  subject(:post_response) { post_graphql_mutation(mutation, current_user: user) }

  it 'returns an error' do
    post_response

    expect_graphql_errors_to_include("The resource that you are attempting to access does not exist " \
                                     "or you don't have permission to perform this action")
  end

  context 'with saas-only feature enabled' do
    before do
      stub_saas_features(google_cloud_support: true)
    end

    shared_examples 'a request returning an error' do |message|
      it 'returns an error' do
        post_response
        expect(graphql_data_at(:provision_google_cloud_runner, :errors)).to match([message])
      end
    end

    it 'returns provisioning steps', :aggregate_failures do
      post_response
      expect_graphql_errors_to_be_empty

      expect(graphql_data_at(:provision_google_cloud_runner, :provisioning_steps)).to match(
        [
          {
            'instructions' => a_string_including(
              "# TODO: Test provisioning runner #{runner_token} on project '#{google_cloud_project_id}'"),
            'languageIdentifier' => 'terraform',
            'title' => 'Terraform script'
          }
        ]
      )
    end

    context 'with nil runner token' do
      let(:runner_token) { nil }

      it 'is successful' do
        post_response
        expect_graphql_errors_to_be_empty
      end

      context 'when user does not have permissions to create runner' do
        before do
          allow(Ability).to receive(:allowed?).and_call_original
          allow(Ability).to receive(:allowed?).with(user, :create_runner, anything).and_return(false)
        end

        it 'returns an error' do
          post_response

          expect_graphql_errors_to_include("The resource that you are attempting to access does not exist " \
                                           "or you don't have permission to perform this action")
        end
      end
    end

    context 'with invalid runner token' do
      let(:runner_token) { 'invalid-token' }

      it_behaves_like 'a request returning an error', 'runnerToken is invalid'
    end

    context 'when user is not authorized' do
      let(:user) { create(:user) }

      it 'returns an error' do
        post_response

        expect_graphql_errors_to_include("The resource that you are attempting to access does not exist " \
                                         "or you don't have permission to perform this action")
      end
    end
  end

  context 'with dryRun set to false' do
    let(:dry_run) { false }

    it 'returns an error' do
      post_response

      expect_graphql_errors_to_include('mutation can currently only run in dry-run mode')
    end
  end
end
