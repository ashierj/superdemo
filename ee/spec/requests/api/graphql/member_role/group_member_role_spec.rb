# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.group_member_role', feature_category: :system_access do
  include GraphqlHelpers

  def member_roles_query(group)
    <<~QUERY
    query {
      group(fullPath: "#{group.full_path}") {
        id
        name
        memberRoles {
          nodes {
            id
            name
            membersCount
          }
        }
      }
    }
    QUERY
  end

  let_it_be(:root_group) { create(:group) }
  let_it_be(:sub_group) { create(:group, parent: root_group) }
  let_it_be(:group_member_role_1) { create(:member_role, namespace: root_group, read_code: true) }
  let_it_be(:group_member_role_2) { create(:member_role, namespace: root_group, read_vulnerability: true) }
  let_it_be(:group_2_member_role) { create(:member_role) }
  let_it_be(:user) { create(:user) }

  subject do
    graphql_data.dig('group', 'memberRoles', 'nodes')
  end

  before_all do
    root_group.add_owner(user)
  end

  shared_examples 'returns member roles' do
    it_behaves_like 'a working graphql query'

    it 'returns all member roles' do
      subject

      expect(subject).to match_array([
        {
          'id' => group_member_role_1.to_global_id.to_s,
          'name' => group_member_role_1.name,
          'membersCount' => 0
        },
        {
          'id' => group_member_role_2.to_global_id.to_s,
          'name' => group_member_role_2.name,
          'membersCount' => 0
        }
      ])
    end
  end

  context 'with custom roles feature' do
    before do
      stub_licensed_features(custom_roles: true)
    end

    context 'for a group with multiple roles' do
      let_it_be(:group) { create(:group) }
      let_it_be(:user) { create(:user) }
      let!(:member_role) { create(:member_role, namespace: group) }

      before_all do
        group.add_owner(user)
      end

      it 'avoids N+1 database queries' do
        post_graphql(member_roles_query(group), current_user: user) # warmup

        control = ActiveRecord::QueryRecorder.new { post_graphql(member_roles_query(group), current_user: user) }

        create(:member_role, namespace: group)

        expect { post_graphql(member_roles_query(group), current_user: user) }.not_to exceed_query_limit(control)
      end
    end

    context 'for a root group' do
      before do
        post_graphql(member_roles_query(root_group), current_user: user)
      end

      it_behaves_like 'returns member roles'
    end

    context 'for subgroup' do
      before do
        post_graphql(member_roles_query(sub_group), current_user: user)
      end

      it_behaves_like 'returns member roles'
    end
  end

  context 'without custom roles feature' do
    before do
      stub_licensed_features(custom_roles: false)

      post_graphql(member_roles_query(root_group), current_user: user)
    end

    it 'does not return any member roles' do
      expect(subject).to be_empty
    end
  end
end
