# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.member_role_permissions', feature_category: :system_access do
  include GraphqlHelpers

  let(:fields) do
    <<~QUERY
      nodes {
        availableFor
        description
        name
        requirement
        value
      }
    QUERY
  end

  let(:query) do
    graphql_query_for('memberRolePermissions', fields)
  end

  before do
    allow(MemberRole).to receive(:all_customizable_permissions).and_return(
      {
        admin_ability_one: {
          description: 'Allows admin access to do something.',
          minimal_level: Gitlab::Access::GUEST
        },
        admin_ability_two: {
          description: 'Allows admin access to do something else.',
          minimal_level: Gitlab::Access::DEVELOPER,
          requirement: :read_ability_two
        },
        read_ability_two: {
          description: 'Allows read access to do something else.',
          minimal_level: Gitlab::Access::GUEST
        }
      }
    )
    allow(MemberRole).to receive(:all_customizable_project_permissions).and_return(
      [:admin_ability_one, :read_ability_two]
    )
    allow(MemberRole).to receive(:all_customizable_group_permissions).and_return(
      [:admin_ability_two, :read_ability_two]
    )

    post_graphql(query)
  end

  subject { graphql_data.dig('memberRolePermissions', 'nodes') }

  it_behaves_like 'a working graphql query'

  it 'returns all customizable ablities' do
    expected_result = [
      { 'availableFor' => ['project'], 'description' => 'Allows admin access to do something.',
        'name' => 'Admin ability one', 'requirement' => nil, 'value' => 'ADMIN_ABILITY_ONE' },
      { 'availableFor' => %w[project group], 'description' => 'Allows read access to do something else.',
        'name' => 'Read ability two', 'requirement' => nil, 'value' => 'READ_ABILITY_TWO' },
      { 'availableFor' => ['group'], 'description' => "Allows admin access to do something else.",
        'requirement' => 'READ_ABILITY_TWO', 'name' => 'Admin ability two', 'value' => 'ADMIN_ABILITY_TWO' }
    ]

    expect(subject).to match_array(expected_result)
  end
end
