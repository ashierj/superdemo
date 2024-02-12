# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupApprovalRules, :aggregate_failures, feature_category: :source_code_management do
  let_it_be(:group) { create(:group_with_members) }
  let_it_be(:group2) { create(:group_with_members) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:admin) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:project) do
    create(:project, :public, :repository, creator: user, group: group,
      only_allow_merge_if_pipeline_succeeds: false)
  end

  let_it_be(:protected_branches) { create_list(:protected_branch, 2, project: project) }
  let_it_be(:approver) { create(:user) }
  let_it_be(:other_approver) { create(:user) }

  before_all do
    group.add_maintainer(user2)
  end

  before do
    stub_licensed_features(merge_request_approvers: true)
  end

  describe 'POST /groups/:id/approval_rules' do
    let(:schema) { 'public_api/v4/group_approval_rule' }
    let(:url) { "/groups/#{group.id}/approval_rules" }
    let(:current_user) { user }
    let(:name) { 'name' }
    let(:params) do
      {
        name: name,
        approvals_required: 10
      }
    end

    context 'when approval_group_rules flag is disabled' do
      before do
        stub_feature_flags(approval_group_rules: false)
      end

      it 'returns 404' do
        post api(url, current_user, admin_mode: current_user.admin?), params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it 'returns 201 status' do
      post api(url, current_user, admin_mode: current_user.admin?), params: params

      expect(response).to have_gitlab_http_status(:created)
      expect(response).to match_response_schema(schema, dir: 'ee')
    end

    context 'when multiple_approval_rules feature is available' do
      before do
        stub_licensed_features(multiple_approval_rules: true)
      end

      it 'returns protected branches' do
        post api(url, current_user, admin_mode: current_user.admin?), params: params

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['protected_branches'].size).to be 2
      end
    end

    context 'when multiple_approval_rules feature is not available' do
      it 'does not return protected branches' do
        post api(url, current_user, admin_mode: current_user.admin?), params: params

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response).not_to include('protected_branches')
      end
    end

    context 'when a user is without access' do
      let(:current_user) { user2 }

      it 'returns 403' do
        post api(url, current_user, admin_mode: current_user.admin?), params: params

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when missing parameters' do
      it 'returns 400 status' do
        post api(url, current_user, admin_mode: current_user.admin?)

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with an invalid parameter' do
      let(:name) { '' }

      it 'returns 400 status' do
        post api(url, current_user, admin_mode: current_user.admin?), params: params

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq({ "name" => ["can't be blank"] })
      end
    end

    context 'with user_id or group_id params' do
      before do
        post api(url, current_user, admin_mode: current_user.admin?), params: params.merge!(extra_params)
      end

      context 'with user_ids' do
        let(:extra_params) { { user_ids: [user2.id] } }

        it 'returns a user' do
          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['users'].size).to be 1
          expect(json_response.dig('users', 0, 'id')).to eq(user2.id)
        end
      end

      context 'with group_ids' do
        let(:extra_params) { { group_ids: [group.id] } }

        it 'returns a group' do
          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['groups'].size).to be 1
          expect(json_response.dig('groups', 0, 'id')).to eq(group.id)
        end
      end
    end
  end
end
