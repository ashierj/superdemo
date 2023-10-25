# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update value stream', feature_category: :value_stream_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:value_stream) { create(:cycle_analytics_value_stream, name: 'Old name') }

  let(:new_name) { 'New name' }

  let(:mutation_name) { :value_stream_update }

  let(:mutation) do
    graphql_mutation(
      mutation_name,
      id: value_stream.to_global_id,
      name: new_name
    )
  end

  before do
    stub_licensed_features(
      cycle_analytics_for_projects: true,
      cycle_analytics_for_groups: true
    )
  end

  context 'when user has permissions to update value streams' do
    before do
      value_stream.namespace.add_reporter(current_user)
    end

    it 'updates the value stream' do
      post_graphql_mutation(mutation, current_user: current_user)

      value_stream = graphql_mutation_response(mutation_name)['valueStream']

      expect(value_stream).to be_present
      expect(value_stream['name']).to eq('New name')
    end

    context 'and uses invalid arguments' do
      let(:new_name) { 'no' }

      it 'returns error' do
        post_graphql_mutation(mutation, current_user: current_user)

        result = graphql_mutation_response(mutation_name)['errors']

        expect(result).to include('Name is too short (minimum is 3 characters)')
      end
    end
  end

  context 'when the user does not have permission to create a value stream' do
    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when Value Stream Analytics is not available for the namespace' do
    before do
      value_stream.namespace.add_reporter(current_user)
      stub_licensed_features(cycle_analytics_for_projects: false)
      stub_licensed_features(cycle_analytics_for_groups: false)
    end

    it_behaves_like 'a mutation that returns a top-level access error'
  end
end
