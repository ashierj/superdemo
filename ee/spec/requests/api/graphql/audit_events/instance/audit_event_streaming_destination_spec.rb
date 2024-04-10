# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'List audit event streaming destinations for the instance', feature_category: :audit_events do
  include GraphqlHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:destination_1) { create(:audit_events_instance_external_streaming_destination) }
  let_it_be(:destination_2) { create(:audit_events_instance_external_streaming_destination) }

  let(:path) { %i[audit_events_instance_streaming_destinations nodes] }

  let(:query) do
    graphql_query_for(
      :audit_events_instance_streaming_destinations
    )
  end

  shared_examples 'a request that returns no destinations' do
    it 'returns no destinations' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data_at(:audit_events_instance_streaming_destinations, :nodes)).to be_empty
    end
  end

  context 'when user is authenticated' do
    context 'when feature is licensed' do
      before do
        stub_licensed_features(external_audit_events: true)
      end

      context 'when user is instance admin' do
        it 'returns the instance audit event streaming destinations', :aggregate_failures do
          post_graphql(query, current_user: admin)

          expect(graphql_data_at(*path)).to contain_exactly(
            a_hash_including(
              'config' => destination_1.config,
              'name' => destination_1.name,
              'category' => destination_1.category
            ),
            a_hash_including(
              'config' => destination_2.config,
              'name' => destination_2.name,
              'category' => destination_2.category
            )
          )

          expect(graphql_data_at(*path))
            .to contain_exactly(
              hash_not_including('secretAccessKey'),
              hash_not_including('secretAccessKey')
            )
        end
      end

      context 'when user is not instance admin' do
        it_behaves_like 'a request that returns no destinations' do
          let(:current_user) { user }
        end
      end
    end

    context 'when feature is not licensed' do
      context 'when user is instance admin' do
        it_behaves_like 'a request that returns no destinations' do
          let(:current_user) { admin }
        end
      end

      context 'when user is not instance admin' do
        it_behaves_like 'a request that returns no destinations' do
          let(:current_user) { user }
        end
      end
    end
  end

  context 'when user is not authenticated' do
    let(:user) { nil }

    context 'when feature is licensed' do
      before do
        stub_licensed_features(external_audit_events: true)
      end

      it_behaves_like 'a request that returns no destinations' do
        let(:current_user) { user }
      end
    end

    context 'when feature is not licensed' do
      it_behaves_like 'a request that returns no destinations' do
        let(:current_user) { user }
      end
    end
  end
end
