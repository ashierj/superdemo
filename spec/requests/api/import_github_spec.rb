# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ImportGithub, feature_category: :importers do
  let(:token) { "ghp_asdasd12345" }
  let(:provider) { :github }
  let(:access_params) { { github_access_token: token } }
  let(:provider_username) { user.username }
  let(:provider_user) { double('provider', login: provider_username).as_null_object }
  let(:provider_repo) do
    {
      name: 'vim',
      full_name: "#{provider_username}/vim",
      owner: double('provider', login: provider_username),
      description: 'provider',
      private: false,
      clone_url: 'https://fake.url/vim.git',
      has_wiki: true
    }
  end

  let(:client) { double('client', user: provider_user, repository: provider_repo) }

  before do
    Grape::Endpoint.before_each do |endpoint|
      allow(endpoint).to receive(:client).and_return(client)
    end
  end

  after do
    Grape::Endpoint.before_each nil
  end

  describe "POST /import/github" do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let(:scopes) { ["repo", "read:org"] }

    before do
      allow(client).to receive_message_chain(:octokit, :rate_limit)
      allow(client).to receive_message_chain(:octokit, :scopes).and_return(scopes)
    end

    it 'rejects requests when Github Importer is disabled' do
      stub_application_setting(import_sources: nil)

      post api("/import/github", user), params: {
        target_namespace: user.namespace_path,
        personal_access_token: token,
        repo_id: non_existing_record_id
      }

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'returns 201 response when the project is imported successfully' do
      allow(Gitlab::LegacyGithubImport::ProjectCreator)
        .to receive(:new).with(provider_repo, provider_repo[:name], user.namespace, user, type: provider, **access_params)
        .and_return(double(execute: project))

      post api("/import/github", user), params: {
        target_namespace: user.namespace_path,
        personal_access_token: token,
        repo_id: non_existing_record_id
      }
      expect(response).to have_gitlab_http_status(:created)
      expect(json_response).to be_a Hash
      expect(json_response['name']).to eq(project.name)
    end

    it 'returns 201 response when the project is imported successfully from GHE' do
      allow(Gitlab::LegacyGithubImport::ProjectCreator)
        .to receive(:new).with(provider_repo, provider_repo[:name], user.namespace, user, type: provider, **access_params)
          .and_return(double(execute: project))

      post api("/import/github", user), params: {
        target_namespace: user.namespace_path,
        personal_access_token: token,
        repo_id: non_existing_record_id,
        github_hostname: "https://github.somecompany.com/",
        optional_stages: { attachments_import: true }
      }
      expect(response).to have_gitlab_http_status(:created)
      expect(json_response).to be_a Hash
      expect(json_response['name']).to eq(project.name)
      expect(json_response).not_to have_key('warning')
    end

    it 'returns 422 response when user can not create projects in the chosen namespace' do
      other_namespace = create(:group, name: 'other_namespace')

      post api("/import/github", user), params: {
        target_namespace: other_namespace.name,
        personal_access_token: token,
        repo_id: non_existing_record_id
      }

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end

    context 'when target_namespace is blank' do
      it 'returns 400 response' do
        allow(Gitlab::LegacyGithubImport::ProjectCreator)
          .to receive(:new).with(provider_repo, provider_repo[:name], user.namespace, user, type: provider, **access_params)
            .and_return(double(execute: project))

        post api("/import/github", user), params: {
          target_namespace: '',
          personal_access_token: token,
          repo_id: non_existing_record_id
        }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq 'target_namespace is empty'
      end
    end

    context 'when unauthenticated user' do
      it 'returns 403 response' do
        post api("/import/github"), params: {
          target_namespace: user.namespace_path,
          personal_access_token: token,
          repo_id: non_existing_record_id
        }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with invalid timeout stategy' do
      it 'returns 400 response' do
        post api("/import/github", user), params: {
          target_namespace: user.namespace_path,
          personal_access_token: token,
          repo_id: non_existing_record_id,
          timeout_strategy: "invalid_strategy"
        }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with a fine-grained token' do
      let(:token) { 'github_pat_asdasd12345' }

      it 'proceeds with the import but returns a PAT warning' do
        allow(Gitlab::LegacyGithubImport::ProjectCreator)
          .to receive(:new).with(provider_repo, provider_repo[:name], user.namespace, user, type: provider, **access_params)
          .and_return(double(execute: project))

        post api("/import/github", user), params: {
          target_namespace: user.namespace_path,
          personal_access_token: token,
          repo_id: non_existing_record_id,
          optional_stages: { collaborators_import: true }
        }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response).to be_a Hash
        expect(json_response['name']).to eq(project.name)
        expect(json_response['import_warning']).to eq("Fine-grained personal access tokens are not officially supported. It is recommended to use a classic token instead.")
      end
    end

    context 'with a non-classic token' do
      let(:token) { 'ghu_asdasd12345' }

      it 'proceeds with the import' do
        allow(Gitlab::LegacyGithubImport::ProjectCreator)
          .to receive(:new).with(provider_repo, provider_repo[:name], user.namespace, user, type: provider, **access_params)
          .and_return(double(execute: project))

        post api("/import/github", user), params: {
          target_namespace: user.namespace_path,
          personal_access_token: token,
          repo_id: non_existing_record_id,
          optional_stages: { collaborators_import: true }
        }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response).to be_a Hash
        expect(json_response['name']).to eq(project.name)
        expect(json_response['import_warning']).to eq(nil)
      end
    end

    context 'when collaborators_import option is not in params' do
      context 'with minimum scope token' do
        let(:scopes) { ['repo'] }

        it 'proceeds with the import' do
          allow(Gitlab::LegacyGithubImport::ProjectCreator)
            .to receive(:new).with(provider_repo, provider_repo[:name], user.namespace, user, type: provider, **access_params)
            .and_return(double(execute: project))

          post api("/import/github", user), params: {
            target_namespace: user.namespace_path,
            personal_access_token: token,
            repo_id: non_existing_record_id
          }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response).to be_a Hash
          expect(json_response['name']).to eq(project.name)
        end
      end

      context 'without minimum scope token' do
        let(:scopes) { ['write:packages'] }

        it 'raises an error' do
          allow(Gitlab::LegacyGithubImport::ProjectCreator)
            .to receive(:new).with(provider_repo, provider_repo[:name], user.namespace, user, type: provider, **access_params)
            .and_return(double(execute: project))

          post api("/import/github", user), params: {
            target_namespace: user.namespace_path,
            personal_access_token: token,
            repo_id: non_existing_record_id
          }

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['errors']).to eq("Your GitHub access token does not have the correct scope to import. Please use a token with the 'repo' scope.")
        end
      end
    end
  end

  describe "POST /import/github/cancel" do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :import_started, import_type: 'github', import_url: 'https://fake.url') }

    context 'when project import was canceled' do
      before do
        allow(Import::Github::CancelProjectImportService)
          .to receive(:new).with(project, user)
          .and_return(double(execute: { status: :success, project: project }))
      end

      it 'returns success' do
        post api("/import/github/cancel", user), params: {
          project_id: project.id
        }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when project import was not canceled' do
      before do
        allow(Import::Github::CancelProjectImportService)
          .to receive(:new).with(project, user)
          .and_return(double(execute: { status: :error, message: 'The import cannot be canceled because it is finished', http_status: :bad_request }))
      end

      it 'returns error' do
        post api("/import/github/cancel", user), params: {
          project_id: project.id
        }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq('The import cannot be canceled because it is finished')
      end
    end

    context 'when unauthenticated user' do
      it 'returns 403 response' do
        post api("/import/github/cancel"), params: {
          project_id: project.id
        }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /import/github/gists' do
    let_it_be(:user) { create(:user) }
    let(:params) { { personal_access_token: token } }

    context 'when gists import was started' do
      before do
        allow(Import::Github::GistsImportService)
          .to receive(:new).with(user, client, access_params)
          .and_return(double(execute: { status: :success }))
      end

      it 'returns 202' do
        post api('/import/github/gists', user), params: params

        expect(response).to have_gitlab_http_status(:accepted)
      end
    end

    context 'when gists import is in progress' do
      before do
        allow(Import::Github::GistsImportService)
          .to receive(:new).with(user, client, access_params)
          .and_return(double(execute: { status: :error, message: 'Import already in progress', http_status: :unprocessable_entity }))
      end

      it 'returns 422 error' do
        post api('/import/github/gists', user), params: params

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response['errors']).to eq('Import already in progress')
      end
    end

    context 'when unauthenticated user' do
      it 'returns 403 error' do
        post api('/import/github/gists'), params: params

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when rate limit reached' do
      before do
        allow(Import::Github::GistsImportService)
          .to receive(:new).with(user, client, access_params)
          .and_raise(Gitlab::GithubImport::RateLimitError)
      end

      it 'returns 429 error' do
        post api('/import/github/gists', user), params: params

        expect(response).to have_gitlab_http_status(:too_many_requests)
      end
    end
  end
end
