# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.single_member_role', feature_category: :system_access do
  include GraphqlHelpers

  def member_role_query
    <<~QUERY
    query {
      memberRole(id: "#{member_role.to_global_id}") {
        id
        name
      }
    }
    QUERY
  end

  let_it_be(:member_role) { create(:member_role) }
  let_it_be(:user) { create(:user) }

  subject do
    graphql_data['memberRole']
  end

  before do
    member_role.namespace.add_owner(user)
  end

  context 'with custom roles feature' do
    before do
      stub_licensed_features(custom_roles: true)
      post_graphql(member_role_query, current_user: user)
    end

    it_behaves_like 'a working graphql query'

    it 'returns the requested member role' do
      expected_result = { 'id' => member_role.to_global_id.to_s, 'name' => member_role.name }

      expect(subject).to eq(expected_result)
    end
  end

  context 'without custom roles feature' do
    before do
      stub_licensed_features(custom_roles: false)

      post_graphql(member_role_query, current_user: user)
    end

    it 'does not return a member role' do
      expect(subject).to be_nil
    end
  end
end
