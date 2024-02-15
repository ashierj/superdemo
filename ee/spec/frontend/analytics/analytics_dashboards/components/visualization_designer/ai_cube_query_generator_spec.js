import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { v4 as uuidv4 } from 'uuid';
import { GlExperimentBadge, GlFormGroup } from '@gitlab/ui';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import generateCubeQueryMutation from 'ee/analytics/analytics_dashboards/graphql/mutations/generate_cube_query.mutation.graphql';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import AiCubeQueryGenerator from 'ee/analytics/analytics_dashboards/components/visualization_designer/ai_cube_query_generator.vue';
import { TEST_VISUALIZATION } from 'ee_jest/analytics/analytics_dashboards/mock_data';

Vue.use(VueApollo);

jest.mock('uuid');

describe('AiCubeQueryGenerator', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;
  const generateCubeQueryMutationHandlerMock = jest.fn();
  const aiResponseSubscriptionHandlerMock = jest.fn();

  const findGenerateCubeQueryPromptInput = () =>
    wrapper.findByTestId('generate-cube-query-prompt-input');
  const findGenerateCubeQuerySubmitButton = () =>
    wrapper.findByTestId('generate-cube-query-submit-button');
  const findExperimentBadge = () => wrapper.findComponent(GlExperimentBadge);

  const createWrapper = () => {
    wrapper = shallowMountExtended(AiCubeQueryGenerator, {
      provide: {
        namespaceId: 'gid://gitlab/Namespace/1',
      },
      apolloProvider: createMockApollo([
        [generateCubeQueryMutation, generateCubeQueryMutationHandlerMock],
        [aiResponseSubscription, aiResponseSubscriptionHandlerMock],
      ]),
      stubs: {
        GlFormGroup,
      },
    });
  };

  beforeEach(() => {
    window.gon = { current_user_id: 1 };
    uuidv4.mockImplementation(() => 'mock-uuid');
    createWrapper();
  });

  afterEach(() => {
    generateCubeQueryMutationHandlerMock.mockReset();
    aiResponseSubscriptionHandlerMock.mockReset();
  });

  it('renders an experiment badge', () => {
    expect(findExperimentBadge().exists()).toBe(true);
  });

  it('does not send a request when no prompt has been entered', async () => {
    findGenerateCubeQuerySubmitButton().vm.$emit('click');

    await waitForPromises();
    expect(generateCubeQueryMutationHandlerMock).not.toHaveBeenCalled();
  });

  describe('when a prompt is submitted', () => {
    const prompt = 'Count of page views grouped weekly';
    const generatedQuery = TEST_VISUALIZATION().data.query;

    beforeEach(() => {
      generateCubeQueryMutationHandlerMock.mockResolvedValue({
        data: { aiAction: { errors: [], __typename: 'AiActionPayload' } },
      });
      aiResponseSubscriptionHandlerMock.mockResolvedValue({
        data: {
          aiCompletionResponse: {
            errors: [],
            content: JSON.stringify(generatedQuery),
          },
        },
      });

      findGenerateCubeQueryPromptInput().vm.$emit('input', prompt);
      findGenerateCubeQuerySubmitButton().vm.$emit('click');
    });

    it('sends a request to the server', () => {
      expect(generateCubeQueryMutationHandlerMock).toHaveBeenCalledWith({
        clientSubscriptionId: 'mock-uuid',
        htmlResponse: false,
        resourceId: 'gid://gitlab/Namespace/1',
        question: prompt,
      });
    });

    it('subscribes to the aiCompletionResponse subscription', () => {
      expect(aiResponseSubscriptionHandlerMock).toHaveBeenCalledWith({
        clientSubscriptionId: 'mock-uuid',
        htmlResponse: true,
        resourceId: 'gid://gitlab/Namespace/1',
        userId: 'gid://gitlab/User/1',
      });
    });

    it('shows a loading indicator', () => {
      expect(findGenerateCubeQuerySubmitButton().props('loading')).toBe(true);
      expect(findGenerateCubeQuerySubmitButton().props('icon')).toBe('');
    });

    describe('when aiCompletionResponse subscription returns a value', () => {
      beforeEach(() => waitForPromises());

      it('stops loading', () => {
        expect(findGenerateCubeQuerySubmitButton().props('loading')).toBe(false);
        expect(findGenerateCubeQuerySubmitButton().props('icon')).toBe('tanuki-ai');
      });

      it('emits generated query', () => {
        expect(wrapper.emitted('query-generated').at(0)).toStrictEqual([generatedQuery]);
      });
    });
  });
});
