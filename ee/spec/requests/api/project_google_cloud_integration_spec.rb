# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectGoogleCloudIntegration, feature_category: :integrations do
  let_it_be(:owner) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:project) { create(:project, namespace: group) }

  let(:google_cloud_project_id) { 'google-cloud-project-id' }

  before_all do
    group.add_owner(owner)
  end

  shared_examples 'an endpoint generating a bash script for Google Cloud' do
    it 'generates the script' do
      get(api(path, owner), params: params)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.content_type).to eql('text/plain')
      expect(response.body).to include("gcloud config set project '#{google_cloud_project_id}'")
    end

    context 'when required param is missing' do
      let(:params) { {} }

      it 'returns error' do
        get(api(path, owner), params: params)

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when user do not have project admin access' do
      let_it_be(:user) { create(:user) }

      before_all do
        group.add_developer(user)
      end

      it 'returns error' do
        get(api(path, user), params: params)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(google_cloud_integration_onboarding: false)
      end

      it 'returns error' do
        get(api(path, owner), params: params)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /projects/:id/scripts/google_cloud/create_wlif' do
    let(:path) { "/projects/#{project.id}/scripts/google_cloud/create_wlif" }
    let(:params) { { google_cloud_project_id: google_cloud_project_id } }

    it_behaves_like 'an endpoint generating a bash script for Google Cloud'
  end

  describe 'GET /projects/:id/scripts/google_cloud/create_iam_policy' do
    let(:path) { "/projects/#{project.id}/scripts/google_cloud/create_iam_policy" }
    let(:params) do
      {
        google_cloud_project_id: google_cloud_project_id,
        google_cloud_workload_identity_pool_id: 'wlif-gitlab',
        oidc_claim_name: 'username',
        oidc_claim_value: 'user@example.com',
        google_cloud_iam_role: 'roles/compute.admin'
      }
    end

    it_behaves_like 'an endpoint generating a bash script for Google Cloud'
  end
end
