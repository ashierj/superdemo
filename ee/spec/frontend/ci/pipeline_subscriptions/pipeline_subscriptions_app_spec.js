import { GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { createAlert } from '~/alert';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PipelineSubscriptionsApp from 'ee/ci/pipeline_subscriptions/pipeline_subscriptions_app.vue';
import getUpstreamSubscriptions from 'ee/ci/pipeline_subscriptions/graphql/queries/get_upstream_subscriptions.query.graphql';
import getDownstreamSubscriptions from 'ee/ci/pipeline_subscriptions/graphql/queries/get_downstream_subscriptions.query.graphql';

import { mockUpstreamSubscriptions, mockDownstreamSubscriptions } from './mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

describe('Pipeline subscriptions app', () => {
  let wrapper;

  const upstreamHanlder = jest.fn().mockResolvedValue(mockUpstreamSubscriptions);
  const downstreamHandler = jest.fn().mockResolvedValue(mockDownstreamSubscriptions);
  const failedHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));

  const findLoadingIcons = () => wrapper.findAllComponents(GlLoadingIcon);

  const defaultHandlers = [
    [getUpstreamSubscriptions, upstreamHanlder],
    [getDownstreamSubscriptions, downstreamHandler],
  ];

  const defaultProvideOptions = {
    projectPath: '/namespace/my-project',
  };

  const createMockApolloProvider = (handlers) => {
    return createMockApollo(handlers);
  };

  const createComponent = (handlers = defaultHandlers) => {
    wrapper = shallowMountExtended(PipelineSubscriptionsApp, {
      provide: {
        ...defaultProvideOptions,
      },
      apolloProvider: createMockApolloProvider(handlers),
    });
  };

  describe('loading state', () => {
    it('shows loading icons', () => {
      createComponent();

      expect(findLoadingIcons()).toHaveLength(2);
    });
  });

  describe('defaults', () => {
    it('does not show loading icons', async () => {
      createComponent();

      await waitForPromises();

      expect(findLoadingIcons()).toHaveLength(0);
    });

    // TODO: when subscriptions table is built ensure they
    // render correctly in this spec for upstream/downstream
  });

  describe('failures', () => {
    it('shows error alert when upstream subscriptions query fetch fails', async () => {
      createComponent([
        [getUpstreamSubscriptions, failedHandler],
        [getDownstreamSubscriptions, downstreamHandler],
      ]);

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred while fetching upstream pipeline subscriptions.',
      });
    });

    it('shows error alert when downstream subscriptions query fetch fails', async () => {
      createComponent([
        [getUpstreamSubscriptions, upstreamHanlder],
        [getDownstreamSubscriptions, failedHandler],
      ]);

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred while fetching downstream pipeline subscriptions.',
      });
    });
  });
});
