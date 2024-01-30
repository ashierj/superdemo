# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Querying user code suggestions access',
  :clean_gitlab_redis_cache, feature_category: :code_suggestions do
  include GraphqlHelpers

  let(:fields) do
    <<~GRAPHQL
      duoCodeSuggestionsAvailable
    GRAPHQL
  end

  let(:query) do
    graphql_query_for('currentUser', fields)
  end

  subject(:graphql_response) { graphql_data.dig('currentUser', 'duoCodeSuggestionsAvailable') }

  context 'when user is not logged in' do
    let(:current_user) { nil }

    it 'returns an empty response' do
      post_graphql(query, current_user: current_user)

      expect(graphql_response).to be_nil
    end
  end

  context 'when user is logged in' do
    let_it_be(:current_user) { create(:user) }

    before do
      allow(Ability)
        .to receive(:allowed?).and_call_original
    end

    context 'when user has access to code suggestions' do
      it 'returns true' do
        expect(GitlabSubscriptions::UserAddOnAssignment)
          .to receive_message_chain(:by_user, :for_active_code_suggestions_purchase).and_return([true])

        post_graphql(query, current_user: current_user)

        expect(graphql_response).to eq(true)
      end
    end

    context 'when user does not have access to code suggestions' do
      it 'returns false' do
        expect(GitlabSubscriptions::UserAddOnAssignment)
          .to receive_message_chain(:by_user, :for_active_code_suggestions_purchase).and_return([])

        post_graphql(query, current_user: current_user)

        expect(graphql_response).to eq(false)
      end
    end

    context 'when feature flag is off' do
      before do
        stub_feature_flags(code_suggestions_tokens_api: false)
      end

      it 'returns false' do
        post_graphql(query, current_user: current_user)

        expect(graphql_response).to eq(false)
      end
    end
  end
end
