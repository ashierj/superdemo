# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'aiMetrics', :freeze_time, feature_category: :value_stream_management do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, name: 'my-group') }
  let_it_be(:current_user) { create(:user, reporter_of: group) }

  let(:filter_params) { {} }

  shared_examples 'common ai metrics' do
    before do
      allow_next_instance_of(::Analytics::AiAnalytics::CodeSuggestionUsageRateService) do |instance|
        allow(instance).to receive(:execute).and_return(ServiceResponse.success(payload: 0.525))
      end

      post_graphql(query, current_user: current_user)
    end

    it 'returns code suggestion metric' do
      expect(ai_metrics).to eq({ 'codeSuggestionsUsageRate' => 52.5 })
    end

    context 'when filter range is too wide' do
      let(:filter_params) { { startDate: 5.years.ago } }

      it 'returns an error' do
        expect_graphql_errors_to_include("maximum date range is 1 year")
        expect(ai_metrics).to be_nil
      end
    end
  end

  context 'for group' do
    let(:query) do
      graphql_query_for(:group, { fullPath: group.full_path },
        query_graphql_field(:aiMetrics, filter_params, 'codeSuggestionsUsageRate'))
    end

    let(:ai_metrics) { graphql_data['group']['aiMetrics'] }

    it_behaves_like 'common ai metrics'
  end

  context 'for project' do
    let_it_be(:project) { create(:project, group: group) }

    let(:query) do
      graphql_query_for(:project, { fullPath: project.full_path },
        query_graphql_field(:aiMetrics, filter_params, 'codeSuggestionsUsageRate'))
    end

    let(:ai_metrics) { graphql_data['project']['aiMetrics'] }

    it_behaves_like 'common ai metrics'
  end
end
