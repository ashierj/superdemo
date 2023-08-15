import { GlSprintf } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';
import TanukiBotChatApp from 'ee/ai/tanuki_bot/components/app.vue';
import AiGenieChat from 'ee/ai/components/ai_genie_chat.vue';
import AiGenieChatConversation from 'ee/ai/components/ai_genie_chat_conversation.vue';
import AiGenieChatMessage from 'ee/ai/components/ai_genie_chat_message.vue';
import UserFeedback from 'ee/ai/components/user_feedback.vue';
import { i18n, GENIE_CHAT_RESET_MESSAGE } from 'ee/ai/constants';
import { TANUKI_BOT_TRACKING_EVENT_NAME } from 'ee/ai/tanuki_bot/constants';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import chatMutation from 'ee/ai/graphql/chat.mutation.graphql';
import tanukiBotMutation from 'ee/ai/graphql/tanuki_bot.mutation.graphql';
import getAiMessages from 'ee/ai/graphql/get_ai_messages.query.graphql';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { getMarkdown } from '~/rest_api';
import { helpCenterState } from '~/super_sidebar/constants';
import {
  MOCK_USER_MESSAGE,
  MOCK_TANUKI_MESSAGE,
  MOCK_USER_ID,
  MOCK_RESOURCE_ID,
  MOCK_TANUKI_SUCCESS_RES,
  MOCK_TANUKI_BOT_MUTATATION_RES,
  MOCK_CHAT_CACHED_MESSAGES_RES,
} from '../mock_data';

Vue.use(Vuex);
Vue.use(VueApollo);

jest.mock('~/rest_api');

describe('GitLab Duo Chat', () => {
  let wrapper;

  const actionSpies = {
    addDuoChatMessage: jest.fn(),
    setMessages: jest.fn(),
    setLoading: jest.fn(),
  };

  const subscriptionHandlerMock = jest.fn().mockResolvedValue(MOCK_TANUKI_SUCCESS_RES);
  const tanukiMutationHandlerMock = jest.fn().mockResolvedValue(MOCK_TANUKI_BOT_MUTATATION_RES);
  let chatMutationHandlerMock = jest.fn().mockResolvedValue(MOCK_TANUKI_BOT_MUTATATION_RES);
  const queryHandlerMock = jest.fn().mockResolvedValue(MOCK_CHAT_CACHED_MESSAGES_RES);

  const createComponent = (
    initialState = {},
    glFeatures = { gitlabDuo: true },
    propsData = { userId: MOCK_USER_ID, resourceId: MOCK_RESOURCE_ID },
  ) => {
    const store = new Vuex.Store({
      actions: actionSpies,
      state: {
        ...initialState,
      },
    });

    const apolloProvider = createMockApollo([
      [aiResponseSubscription, subscriptionHandlerMock],
      [chatMutation, chatMutationHandlerMock],
      [tanukiBotMutation, tanukiMutationHandlerMock],
      [getAiMessages, queryHandlerMock],
    ]);

    wrapper = shallowMountExtended(TanukiBotChatApp, {
      store,
      apolloProvider,
      propsData,
      stubs: {
        AiGenieChat,
        GlSprintf,
        AiGenieChatConversation,
        AiGenieChatMessage,
      },
      provide: {
        glFeatures,
      },
    });
  };

  const findWarning = () => wrapper.findByTestId('chat-legal-warning');
  const findGenieChat = () => wrapper.findComponent(AiGenieChat);
  const findGeneratedByAI = () => wrapper.findByText(i18n.GENIE_CHAT_LEGAL_GENERATED_BY_AI);
  const findAllUserFeedback = () => wrapper.findAllComponents(UserFeedback);

  beforeEach(() => {
    getMarkdown.mockImplementation(({ text }) => Promise.resolve({ data: { html: text } }));
  });

  describe('rendering', () => {
    beforeEach(() => {
      createComponent();
      helpCenterState.showTanukiBotChatDrawer = true;
    });

    it('renders a legal info when rendered', () => {
      expect(findWarning().exists()).toBe(true);
    });

    it('renders a generated by AI note', () => {
      expect(findGeneratedByAI().exists()).toBe(true);
    });

    it('passes down the example prompts', () => {
      expect(findGenieChat().props().predefinedPrompts).toEqual(
        wrapper.vm.$options.i18n.predefinedPrompts,
      );
    });
  });

  describe('AiGenieChat interactions', () => {
    beforeEach(() => {
      createComponent();
      helpCenterState.showTanukiBotChatDrawer = true;
    });

    it('closes the chat on @chat-hidden', async () => {
      findGenieChat().vm.$emit('chat-hidden');
      await nextTick();
      expect(helpCenterState.showTanukiBotChatDrawer).toBe(false);
      expect(findGenieChat().exists()).toBe(false);
    });
  });

  describe('Chat', () => {
    beforeEach(() => {
      createComponent();
      helpCenterState.showTanukiBotChatDrawer = true;
    });

    it('renders AiGenieChat component', () => {
      expect(findGenieChat().exists()).toBe(true);
    });

    it('fetches the cached messages on mount', () => {
      expect(queryHandlerMock).toHaveBeenCalled();
    });

    it('renders the User Feedback component for every assistent mesage', () => {
      createComponent({
        messages: [MOCK_USER_MESSAGE, MOCK_TANUKI_MESSAGE, MOCK_USER_MESSAGE, MOCK_TANUKI_MESSAGE],
      });

      expect(findAllUserFeedback().length).toBe(2);

      findAllUserFeedback().wrappers.forEach((component) => {
        expect(component.props('eventName')).toBe(TANUKI_BOT_TRACKING_EVENT_NAME);
        expect(component.props('promptLocation')).toBe('after_content');
      });
    });

    describe('when input is submitted', () => {
      beforeEach(() => {
        findGenieChat().vm.$emit('send-chat-prompt', MOCK_USER_MESSAGE.msg);
      });

      describe('loading state', () => {
        it('does set loading to `true` for a message other than the reset one', () => {
          expect(actionSpies.setLoading).toHaveBeenCalled();
        });
        it('does not set loading to `true` for a reset message', async () => {
          actionSpies.setLoading.mockReset();
          findGenieChat().vm.$emit('send-chat-prompt', GENIE_CHAT_RESET_MESSAGE);
          await nextTick();
          expect(actionSpies.setLoading).not.toHaveBeenCalled();
        });
      });

      describe.each`
        resourceId          | expectedResourceId
        ${MOCK_RESOURCE_ID} | ${MOCK_RESOURCE_ID}
        ${null}             | ${MOCK_USER_ID}
      `(`with resourceId = $resourceId`, ({ resourceId, expectedResourceId }) => {
        it.each`
          isFlagEnabled | expectedMutation
          ${true}       | ${chatMutationHandlerMock}
          ${false}      | ${tanukiMutationHandlerMock}
        `(
          'calls correct GraphQL mutation with fallback to userId when input is submitted and feature flag is $isFlagEnabled',
          async ({ isFlagEnabled, expectedMutation } = {}) => {
            createComponent({}, { gitlabDuo: isFlagEnabled }, { userId: MOCK_USER_ID, resourceId });
            findGenieChat().vm.$emit('send-chat-prompt', MOCK_USER_MESSAGE.msg);

            await nextTick();

            expect(expectedMutation).toHaveBeenCalledWith({
              resourceId: expectedResourceId,
              question: MOCK_USER_MESSAGE.msg,
            });
          },
        );

        it('once response arrives via GraphQL subscription with userId fallback calls addDuoChatMessage', () => {
          createComponent({}, {}, { userId: MOCK_USER_ID, resourceId });

          expect(subscriptionHandlerMock).toHaveBeenCalledWith({
            resourceId: expectedResourceId,
            userId: MOCK_USER_ID,
          });
          expect(actionSpies.addDuoChatMessage).toHaveBeenCalledWith(
            expect.any(Object),
            MOCK_TANUKI_SUCCESS_RES.data.aiCompletionResponse,
          );
        });
      });
    });
  });

  describe('Error conditions', () => {
    describe('when subscription fails', () => {
      const error = 'foo';
      describe.each`
        resourceId          | expectedResourceId
        ${MOCK_RESOURCE_ID} | ${MOCK_RESOURCE_ID}
        ${null}             | ${MOCK_USER_ID}
      `(`with resourceId = $resourceId`, ({ resourceId, expectedResourceId }) => {
        beforeEach(async () => {
          subscriptionHandlerMock.mockRejectedValue(error);
          createComponent({}, { gitlabDuo: true }, { userId: MOCK_USER_ID, resourceId });

          helpCenterState.showTanukiBotChatDrawer = true;
          await nextTick();

          findGenieChat().vm.$emit('send-chat-prompt', MOCK_USER_MESSAGE.msg);
        });

        it('once error arrives via GraphQL subscription calls addDuoChatMessage', () => {
          expect(subscriptionHandlerMock).toHaveBeenCalledWith({
            resourceId: expectedResourceId,
            userId: MOCK_USER_ID,
          });
          expect(actionSpies.addDuoChatMessage).toHaveBeenCalledWith(expect.any(Object), {
            errors: [error],
          });
        });
      });
    });

    describe('when mutation fails', () => {
      beforeEach(async () => {
        chatMutationHandlerMock = jest.fn().mockRejectedValue('foo');
        createComponent();

        helpCenterState.showTanukiBotChatDrawer = true;
        await nextTick();
        findGenieChat().vm.$emit('send-chat-prompt', MOCK_USER_MESSAGE.msg);
      });

      it('calls addDuoChatMessage', () => {
        expect(actionSpies.addDuoChatMessage).toHaveBeenCalledWith(expect.any(Object), {
          errors: ['foo'],
        });
      });
    });
  });
});
