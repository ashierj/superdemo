# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Admin::Search::Zoekt, :zoekt, feature_category: :global_search do
  let(:admin) { create(:admin) }
  let_it_be(:namespace) { create(:group) }
  let_it_be(:unindexed_namespace) { create(:group) }
  let_it_be(:project) { create(:project) }
  let(:project_id) { project.id }
  let(:namespace_id) { namespace.id }
  let(:params) { {} }
  let(:node) { ::Search::Zoekt::Node.first }
  let(:node_id) { node.id }

  shared_examples 'an API that returns 400 when the index_code_with_zoekt feature flag is disabled' do |verb|
    before do
      stub_feature_flags(index_code_with_zoekt: false)
    end

    it 'returns not_found status' do
      send(verb, api(path, admin, admin_mode: true))

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['error']).to eq('index_code_with_zoekt feature flag is not enabled')
    end
  end

  shared_examples 'an API that returns 404 for missing ids' do |verb|
    it 'returns not_found status' do
      send(verb, api(path, admin, admin_mode: true))

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'an API that returns 401 for unauthenticated requests' do |verb|
    it 'returns not_found status' do
      send(verb, api(path, nil))

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  describe 'PUT /admin/zoekt/projects/:projects/index' do
    let(:path) { "/admin/zoekt/projects/#{project_id}/index" }

    it_behaves_like "PUT request permissions for admin mode"
    it_behaves_like "an API that returns 401 for unauthenticated requests", :put
    it_behaves_like "an API that returns 400 when the index_code_with_zoekt feature flag is disabled", :put

    it 'triggers indexing for the project' do
      expect(::Zoekt::IndexerWorker).to receive(:perform_async).with(project.id).and_return('the-job-id')

      put api(path, admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['job_id']).to eq('the-job-id')
    end

    it_behaves_like 'an API that returns 404 for missing ids', :put do
      let(:project_id) { non_existing_record_id }
    end
  end

  describe 'GET /admin/zoekt/shards' do
    let(:path) { '/admin/zoekt/shards' }
    let!(:another_node) do
      create(:zoekt_node, index_base_url: 'http://111.111.111.111/', search_base_url: 'http://111.111.111.112/')
    end

    it_behaves_like "GET request permissions for admin mode"
    it_behaves_like "an API that returns 401 for unauthenticated requests", :get

    it 'returns all nodes' do
      get api(path, admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to match_array([
        hash_including(
          'id' => node.id,
          'index_base_url' => node.index_base_url,
          'search_base_url' => node.search_base_url
        ),
        hash_including(
          'id' => another_node.id,
          'index_base_url' => 'http://111.111.111.111/',
          'search_base_url' => 'http://111.111.111.112/'
        )
      ])
    end
  end

  describe 'GET /admin/zoekt/shards/:node_id/indexed_namespaces' do
    let(:path) { "/admin/zoekt/shards/#{node_id}/indexed_namespaces" }
    let!(:indexed_namespace) { create(:zoekt_indexed_namespace, node: node, namespace: namespace) }
    let!(:another_node) do
      create(:zoekt_node, index_base_url: 'http://111.111.111.198/', search_base_url: 'http://111.111.111.199/')
    end

    let!(:indexed_namespace_for_another_node) do
      create(:zoekt_indexed_namespace, node: another_node, namespace: create(:namespace))
    end

    let!(:another_indexed_namespace) do
      create(:zoekt_indexed_namespace, node: node, namespace: create(:namespace))
    end

    it_behaves_like "GET request permissions for admin mode"
    it_behaves_like "an API that returns 401 for unauthenticated requests", :get

    it 'returns all indexed namespaces for this node' do
      get api(path, admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to match_array([
        hash_including(
          'id' => indexed_namespace.id,
          'zoekt_shard_id' => node.id,
          'zoekt_node_id' => node.id,
          'namespace_id' => namespace.id
        ),
        hash_including(
          'id' => another_indexed_namespace.id,
          'zoekt_shard_id' => node.id,
          'zoekt_node_id' => node.id,
          'namespace_id' => another_indexed_namespace.namespace_id
        )
      ])
    end

    it 'returns at most MAX_RESULTS most recent rows' do
      stub_const("#{described_class}::MAX_RESULTS", 1)

      get api(path, admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to match_array([
        hash_including(
          'id' => another_indexed_namespace.id,
          'zoekt_shard_id' => node.id,
          'zoekt_node_id' => node.id,
          'namespace_id' => another_indexed_namespace.namespace_id
        )
      ])
    end

    it_behaves_like 'an API that returns 404 for missing ids', :get do
      let(:node_id) { non_existing_record_id }
    end
  end

  describe 'PUT /admin/zoekt/shards/:node_id/indexed_namespaces/:namespace_id' do
    let(:path) { "/admin/zoekt/shards/#{node_id}/indexed_namespaces/#{namespace_id}" }

    it_behaves_like "PUT request permissions for admin mode"
    it_behaves_like "an API that returns 401 for unauthenticated requests", :put
    it_behaves_like "an API that returns 400 when the index_code_with_zoekt feature flag is disabled", :put

    it 'creates a Zoekt::IndexedNamespace with search enabled for this node and namespace pair' do
      expect do
        put api(path, admin, admin_mode: true)
      end.to change { ::Zoekt::IndexedNamespace.count }.from(0).to(1)

      expect(response).to have_gitlab_http_status(:ok)
      np = ::Zoekt::IndexedNamespace.find_by(node: node, namespace: namespace)
      expect(json_response['id']).to eq(np.id)
      expect(np.search).to eq(true)
    end

    context 'when search parameter is set to false' do
      let(:path) { "/admin/zoekt/shards/#{node_id}/indexed_namespaces/#{namespace_id}?search=false" }

      it 'creates a Zoekt::IndexedNamespace with search disabled for this node and namespace pair' do
        expect do
          put api(path, admin, admin_mode: true)
        end.to change { ::Zoekt::IndexedNamespace.count }.from(0).to(1)

        expect(response).to have_gitlab_http_status(:ok)
        np = ::Zoekt::IndexedNamespace.find_by(node: node, namespace: namespace)
        expect(json_response['id']).to eq(np.id)
        expect(np.search).to eq(false)
      end
    end

    context 'when it already exists' do
      it 'returns the existing one' do
        id = create(:zoekt_indexed_namespace, node: node, namespace: namespace).id

        put api(path, admin, admin_mode: true)

        expect(json_response['id']).to eq(id)
      end

      context 'and search parameter is not present' do
        let(:path) { "/admin/zoekt/shards/#{node_id}/indexed_namespaces/#{namespace_id}" }

        it 'does not change the search attribute' do
          np = create(:zoekt_indexed_namespace, node: node, namespace: namespace, search: false)
          put api(path, admin, admin_mode: true)
          expect(json_response['id']).to eq(np.id)
          np.reload
          expect(np.search).to eq(false)
        end
      end

      context 'and search parameter is set to true' do
        let(:path) { "/admin/zoekt/shards/#{node_id}/indexed_namespaces/#{namespace_id}?search=true" }

        it 'changes the search attribute to true' do
          np = create(:zoekt_indexed_namespace, node: node, namespace: namespace, search: false)
          expect { put api(path, admin, admin_mode: true) }.to change { np.reload.search }.from(false).to(true)
          expect(json_response['id']).to eq(np.id)
        end
      end

      context 'and search parameter is set to false' do
        let(:path) { "/admin/zoekt/shards/#{node_id}/indexed_namespaces/#{namespace_id}?search=false" }

        it 'changes the search attribute to false' do
          np = create(:zoekt_indexed_namespace, node: node, namespace: namespace, search: true)
          expect { put api(path, admin, admin_mode: true) }.to change { np.reload.search }.from(true).to(false)
          expect(json_response['id']).to eq(np.id)
        end
      end
    end

    context 'with missing node_id' do
      it_behaves_like 'an API that returns 404 for missing ids', :put do
        let(:node_id) { non_existing_record_id }
      end
    end

    context 'with missing namespace_id' do
      it_behaves_like 'an API that returns 404 for missing ids', :put do
        let(:namespace_id) { non_existing_record_id }
      end
    end
  end

  describe 'DELETE /admin/zoekt/shards/:node_id/indexed_namespaces/:namespace_id' do
    let(:path) { "/admin/zoekt/shards/#{node_id}/indexed_namespaces/#{namespace_id}" }

    before do
      create(:zoekt_indexed_namespace, node: node, namespace: namespace)
    end

    it_behaves_like "DELETE request permissions for admin mode"
    it_behaves_like "an API that returns 401 for unauthenticated requests", :delete

    it 'removes the Zoekt::IndexedNamespace for this node and namespace pair' do
      expect do
        delete api(path, admin, admin_mode: true)
      end.to change { ::Zoekt::IndexedNamespace.count }.from(1).to(0)

      expect(response).to have_gitlab_http_status(:no_content)
    end

    context 'with missing node_id' do
      it_behaves_like 'an API that returns 404 for missing ids', :delete do
        let(:node_id) { non_existing_record_id }
      end
    end

    context 'with missing namespace_id' do
      it_behaves_like 'an API that returns 404 for missing ids', :delete do
        let(:namespace_id) { non_existing_record_id }
      end
    end
  end
end
