# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::GitHttpController, feature_category: :source_code_management do
  include EE::GeoHelpers
  include GitHttpHelpers

  context 'when repository container is a group wiki' do
    include WikiHelpers

    let_it_be(:group) { create(:group, :wiki_repo) }
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { nil }

    before_all do
      group.add_owner(user)
    end

    before do
      stub_group_wikis(true)
    end

    it_behaves_like described_class do
      let(:container) { group.wiki }
      let(:access_checker_class) { Gitlab::GitAccessWiki }
    end
  end

  context 'git audit streaming event' do
    it_behaves_like 'sends git audit streaming event' do
      subject do
        post :git_upload_pack, params: { repository_path: "#{project.full_path}.git" }
      end
    end
  end

  context 'group IP restriction' do
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:project) { create(:project, :public, :repository, group: group) }

    let(:repository_path) { "#{project.full_path}.git" }
    let(:params) { { repository_path: repository_path, service: 'git-upload-pack' } }

    before do
      stub_licensed_features(group_ip_restriction: true)
      allow(controller).to receive(:verify_workhorse_api!).and_return(true)
    end

    subject(:send_request) {  get :info_refs, params: params }

    context 'without enforced IP allowlist' do
      it 'allows the request' do
        send_request

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with enforced IP allowlist' do
      before_all do
        create(:ip_restriction, group: group, range: '192.168.0.0/24')
      end

      context 'when IP is allowed' do
        before do
          request.env['REMOTE_ADDR'] = '192.168.0.42'
        end

        it 'allows the request' do
          send_request

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when IP is not allowed' do
        before do
          request.env['REMOTE_ADDR'] = '42.42.42.42'
        end

        it 'returns unauthorized' do
          send_request

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end
  end

  shared_context 'with public deploy keys and Geo proxied request' do
    let_it_be(:admin) { create(:user, :admin) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :private, :repository, namespace: group) }
    let_it_be(:geo_node) do
      create(:geo_node_with_selective_sync_for, :primary, model: project, namespaces: :model_parent)
    end

    let_it_be(:repository_path) { "#{project.full_path}.git" }

    let_it_be_with_reload(:deploy_key) { create(:deploy_key, public: true, user: admin) }

    let(:decoded_headers) do
      { scope: project.full_path, gl_id: "key-#{deploy_key.id}" }
    end

    before do
      stub_licensed_features(geo: true)
      stub_current_geo_node(geo_node)

      allow(::Gitlab::Geo::JwtRequestDecoder).to receive(:geo_auth_attempt?).and_return(true)
      allow(controller).to receive(:verify_workhorse_api!).and_return(true)

      allow_next_instance_of(::Gitlab::Geo::JwtRequestDecoder) do |instance|
        allow(instance).to receive(:decode).and_return(decoded_headers)
      end
    end
  end

  shared_examples 'a request with write access needed' do
    include_context 'with public deploy keys and Geo proxied request'

    context 'and write access is granted' do
      it 'returns a successful response' do
        deploy_key.projects << project
        deploy_key.save!

        deploy_keys_project = deploy_key.deploy_keys_project_for(project)
        deploy_keys_project.update!(can_push: true)

        subject

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'and write access is not granted' do
      it 'returns a failed response' do
        deploy_key.projects << project
        deploy_key.save!

        subject

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(response.body).to eq("This deploy key does not have write access to this project.")
      end
    end
  end

  shared_examples 'a request without write access needed' do
    include_context 'with public deploy keys and Geo proxied request'

    context 'and enabled for project' do
      it 'returns a successful response' do
        deploy_key.projects << project
        deploy_key.save!

        subject

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'and disabled for project' do
      let(:expected_response) do
        "The project you were looking for could not be found or you don't have permission to view it."
      end

      it 'returns a failed response' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
        expect(response.body).to eq(expected_response)
      end
    end
  end

  context 'GET #git_upload_pack' do
    subject do
      get :info_refs, params: { repository_path: repository_path, service: 'git-upload-pack' }
    end

    it_behaves_like 'a request without write access needed'
  end

  context 'POST #git_upload_pack' do
    subject do
      post :git_upload_pack, params: { repository_path: repository_path }
    end

    it_behaves_like 'a request without write access needed'
  end

  context 'GET #git_receive_pack' do
    subject do
      get :git_receive_pack, params: { repository_path: repository_path }
    end

    it_behaves_like 'a request with write access needed'
  end

  context 'POST #git_receive_pack' do
    subject do
      post :git_receive_pack, params: { repository_path: repository_path }
    end

    it_behaves_like 'a request with write access needed'
  end
end
