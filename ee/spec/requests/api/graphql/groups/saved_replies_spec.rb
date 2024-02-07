# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group saved replies', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:saved_reply) { create(:group_saved_reply, group: group) }

  let(:query) do
    <<~QUERY
      query groupSavedReplies($groupPath: ID!) {
        group(fullPath: $groupPath) {
          id
          savedReplies {
            nodes {
              id
              name
              content
            }
          }
        }
      }
    QUERY
  end

  subject(:post_query) do
    post_graphql(
      query,
      current_user: user,
      variables: {
        groupPath: group.full_path
      }
    )
  end

  before_all do
    group.add_maintainer(user)
  end

  context 'when license is invalid' do
    before do
      stub_licensed_features(group_saved_replies: false)
    end

    it 'returns empty array' do
      post_query

      expect(saved_reply_graphl_response).to be_empty
    end
  end

  context 'when group_saved_replies_flag feature flag is disabled' do
    before do
      stub_feature_flags(group_saved_replies_flag: false)
      stub_licensed_features(group_saved_replies: true)
    end

    it 'returns empty array' do
      post_query

      expect(saved_reply_graphl_response).to be_empty
    end
  end

  context 'when license is valid' do
    before do
      stub_licensed_features(group_saved_replies: true)
    end

    it 'returns group saved reply' do
      post_query

      expect(saved_reply_graphl_response).to contain_exactly(a_graphql_entity_for(saved_reply, :name, :content))
    end
  end

  def saved_reply_graphl_response
    graphql_dig_at(graphql_data, :group, :saved_replies, :nodes)
  end
end
