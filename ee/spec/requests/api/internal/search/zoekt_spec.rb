# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::Search::Zoekt, feature_category: :global_search do
  include GitlabShellHelpers
  include APIInternalBaseHelpers

  describe 'GET /internal/search/zoekt/:uuid/tasks' do
    let(:endpoint) { "/internal/search/zoekt/#{uuid}/tasks" }
    let(:uuid) { '3869fe21-36d1-4612-9676-0b783ef2dcd7' }
    let(:valid_params) do
      {
        'uuid' => uuid,
        'node.url' => 'http://localhost:6090',
        'node.name' => 'm1.local',
        'disk.all' => 994662584320,
        'disk.used' => 532673712128,
        'disk.free' => 461988872192
      }
    end

    context 'with invalid auth' do
      it 'returns 401' do
        get api(endpoint),
          params: valid_params,
          headers: gitlab_shell_internal_api_request_header(issuer: 'gitlab-workhorse')

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with valid auth' do
      context 'when a task request is received with valid params' do
        it 'returns shard ID for task request' do
          shard = instance_double(::Zoekt::Shard, id: 123)
          expect(::Zoekt::Shard).to receive(:find_or_initialize_by_task_request).with(valid_params).and_return(shard)
          expect(shard).to receive(:save).and_return(true)

          get api(endpoint), params: valid_params, headers: gitlab_shell_internal_api_request_header

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq({ 'id' => shard.id })
        end
      end

      context 'when a heartbeat has valid params but a shard validation error occurs' do
        it 'returns 422' do
          shard = ::Zoekt::Shard.new(search_base_url: nil) # null attributes makes this invalid
          expect(::Zoekt::Shard).to receive(:find_or_initialize_by_task_request).with(valid_params).and_return(shard)
          get api(endpoint), params: valid_params, headers: gitlab_shell_internal_api_request_header
          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end
      end

      context 'when a heartbeat is received with invalid params' do
        it 'returns 400' do
          get api(endpoint), params: { 'foo' => 'bar' }, headers: gitlab_shell_internal_api_request_header
          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end
    end
  end
end
