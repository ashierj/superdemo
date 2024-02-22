import { GlDuoChat, GlExperimentBadge } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { getMarkdown } from '~/rest_api';
import ShowAgent from 'ee/ml/ai_agents/views/show_agent.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import chatMutation from 'ee/ai/graphql/chat.mutation.graphql';
import {
  MOCK_USER_MESSAGE,
  MOCK_USER_ID,
  MOCK_TANUKI_SUCCESS_RES,
  MOCK_TANUKI_BOT_MUTATATION_RES,
} from '../../../ai/tanuki_bot/mock_data';

Vue.use(VueApollo);

jest.mock('~/rest_api');

describe('ee/ml/ai_agents/views/create_agent', () => {
  let wrapper;

  const subscriptionHandlerMock = jest.fn().mockResolvedValue(MOCK_TANUKI_SUCCESS_RES);
  const chatMutationHandlerMock = jest.fn().mockResolvedValue(MOCK_TANUKI_BOT_MUTATATION_RES);
  const agentId = 2;

  const findTitleArea = () => wrapper.findComponent(TitleArea);
  const findBadge = () => wrapper.findComponent(GlExperimentBadge);
  const findGlDuoChat = () => wrapper.findComponent(GlDuoChat);

  const createWrapper = () => {
    const apolloProvider = createMockApollo([
      [aiResponseSubscription, subscriptionHandlerMock],
      [chatMutation, chatMutationHandlerMock],
    ]);

    wrapper = shallowMountExtended(ShowAgent, {
      apolloProvider,
      provide: { projectPath: 'path/to/project', userId: MOCK_USER_ID },
      mocks: {
        $route: {
          params: {
            agentId,
          },
        },
      },
    });
  };

  beforeEach(() => {
    getMarkdown.mockImplementation(({ text }) => Promise.resolve({ data: { html: text } }));
  });

  describe('rendering', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('shows the title', () => {
      expect(findTitleArea().text()).toContain('AI Agent: 2');
    });

    it('displays the experiment badge', () => {
      expect(findBadge().exists()).toBe(true);
    });

    it('renders the DuoChat component', () => {
      expect(findGlDuoChat().exists()).toBe(true);
    });
  });

  describe('@send-chat-prompt', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('does set loading to `true` for a user message', async () => {
      findGlDuoChat().vm.$emit('send-chat-prompt', MOCK_USER_MESSAGE.content);
      await nextTick();
      expect(findGlDuoChat().props('isLoading')).toBe(true);
    });

    it('calls correct GraphQL mutation', async () => {
      findGlDuoChat().vm.$emit('send-chat-prompt', MOCK_USER_MESSAGE.content);
      await nextTick();
      expect(chatMutationHandlerMock).toHaveBeenCalledWith({
        resourceId: MOCK_USER_ID,
        agentVersionId: `gid://gitlab/Ai::AgentVersion/${agentId}`,
        question: MOCK_USER_MESSAGE.content,
      });
    });
  });

  describe('Error conditions', () => {
    const errorText = 'Fancy foo';

    describe('when subscription fails', () => {
      beforeEach(async () => {
        subscriptionHandlerMock.mockRejectedValue(new Error(errorText));
        createWrapper();
        await waitForPromises();
      });

      it('throws error and displays error message', () => {
        expect(findGlDuoChat().props('error')).toBe(`Error: ${errorText}`);
      });
    });

    describe('when mutation fails', () => {
      beforeEach(async () => {
        chatMutationHandlerMock.mockRejectedValue(new Error(errorText));
        createWrapper();
        await waitForPromises();
        findGlDuoChat().vm.$emit('send-chat-prompt', MOCK_USER_MESSAGE.content);
        await waitForPromises();
      });

      it('throws error and displays error message', () => {
        expect(findGlDuoChat().props('error')).toBe(`Error: ${errorText}`);
      });
    });
  });
});
