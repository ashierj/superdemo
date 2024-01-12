// fixtures located in ee/spec/frontend/fixtures/pipeline_subscriptions.rb
import mockUpstreamSubscriptions from 'test_fixtures/graphql/pipeline_subscriptions/upstream.json';
import mockDownstreamSubscriptions from 'test_fixtures/graphql/pipeline_subscriptions/downstream.json';

export const deleteMutationResponse = {
  data: {
    projectSubscriptionDelete: {
      project: {
        id: 'gid://gitlab/Project/20',
        __typename: 'Project',
      },
      errors: [],
      __typename: 'ProjectSubscriptionDeletePayload',
    },
  },
};

export { mockUpstreamSubscriptions, mockDownstreamSubscriptions };
