# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User with admin_cicd_variables custom role', feature_category: :secrets_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:role) { create(:member_role, :guest, namespace: group, admin_cicd_variables: true) }
  let_it_be(:member) { create(:group_member, :guest, member_role: role, user: user, group: group) }

  before do
    stub_licensed_features(custom_roles: true)

    sign_in(user)
  end

  describe Groups::Settings::CiCdController do
    describe '#show' do
      it 'user can view CI/CD settings page' do
        get group_settings_ci_cd_path(group)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include('CI/CD Settings')
      end
    end
  end

  describe 'Querying CI Variables and environment scopes' do
    include GraphqlHelpers

    let_it_be(:variable) do
      create(:ci_group_variable, key: 'new_key', value: 'dummy_value', group: group, environment_scope: 'test_scope')
    end

    let(:query) do
      %(
        query {
          group(fullPath: "#{group.full_path}") {
            ciVariables {
              nodes {
                key
                value
              }
            }
            environmentScopes {
              nodes {
                name
              }
            }
          }
        }
      )
    end

    it 'returns variables and scopes for the group' do
      result = GitlabSchema.execute(query, context: { current_user: user }).as_json

      group_data = result.dig('data', 'group')

      expect(group_data.dig('ciVariables', 'nodes').first).to eq('key' => variable.key, 'value' => variable.value)
      expect(group_data.dig('environmentScopes', 'nodes').first).to eq('name' => variable.environment_scope)
    end
  end

  describe Groups::VariablesController do
    describe '#update' do
      it 'user can create CI/CD variables' do
        params = { variables_attributes: [{ key: 'new_key', secret_value: 'dummy_value' }] }
        put group_variables_path(group, params: params, format: :json)

        expect(response).to have_gitlab_http_status(:ok)
        expect(Gitlab::Json.parse(response.body)['variables'][0])
          .to include('key' => 'new_key', 'value' => 'dummy_value')
      end

      it 'user can update CI/CD variables' do
        var = create(:ci_group_variable, group: group)

        params = { variables_attributes: [{ id: var.id, key: 'new_key', secret_value: 'dummy_value' }] }
        put group_variables_path(group, params: params, format: :json)

        expect(response).to have_gitlab_http_status(:ok)
        expect(Gitlab::Json.parse(response.body)['variables'][0])
          .to include('key' => 'new_key', 'value' => 'dummy_value')
      end

      it 'user can destroy CI/CD variables' do
        var = create(:ci_group_variable, group: group)

        params = { variables_attributes: [{ id: var.id, _destroy: 'true' }] }
        put group_variables_path(group, params: params, format: :json)

        expect(response).to have_gitlab_http_status(:ok)
        expect { var.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
