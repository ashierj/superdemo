# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.group_member_role', feature_category: :system_access do
  include GraphqlHelpers

  def member_roles_query
    <<~QUERY
    {
      memberRoles {
        nodes {
          id
          name
        }
      }
    }
    QUERY
  end

  let_it_be(:group_member_role) { create(:member_role, read_code: true) }
  let_it_be(:instance_role) { create(:member_role, :instance, read_vulnerability: true) }
  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:admin) }

  subject(:roles) do
    graphql_data.dig('memberRoles', 'nodes')
  end

  before_all do
    group_member_role.namespace.add_owner(user)
  end

  context 'with custom roles feature', :enable_admin_mode do
    before do
      stub_licensed_features(custom_roles: true)
    end

    context 'for an instance admin' do
      before do
        post_graphql(member_roles_query, current_user: admin)
      end

      context 'when running on gitlab.com', :saas do
        it 'raises an error' do
          expect { roles }.to raise_error { ArgumentError }
        end
      end

      context 'on self-managed' do
        it_behaves_like 'a working graphql query'

        it 'returns instance roles' do
          expected_result = [
            { 'id' => instance_role.to_global_id.to_s, 'name' => instance_role.name }
          ]

          expect(roles).to match_array(expected_result)
        end
      end
    end

    context 'for a group owner' do
      before do
        post_graphql(member_roles_query, current_user: user)
      end

      it 'does not return any member roles' do
        expect { roles }.to raise_error { ArgumentError }
      end
    end
  end

  context 'without custom roles feature', :enable_admin_mode do
    before do
      stub_licensed_features(custom_roles: false)

      post_graphql(member_roles_query, current_user: admin)
    end

    it 'does not return any member roles' do
      expect { roles }.to raise_error { ArgumentError }
    end
  end
end
