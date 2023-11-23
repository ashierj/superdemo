import { GlDuoChat } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import { v4 as uuidv4 } from 'uuid';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';
import TanukiBotChatApp from 'ee/ai/tanuki_bot/components/app.vue';
import DuoChatCallout from 'ee/ai/components/global_callout/duo_chat_callout.vue';
import { GENIE_CHAT_RESET_MESSAGE } from 'ee/ai/constants';
import { TANUKI_BOT_TRACKING_EVENT_NAME } from 'ee/ai/tanuki_bot/constants';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import chatMutation from 'ee/ai/graphql/chat.mutation.graphql';
import getAiMessages from 'ee/ai/graphql/get_ai_messages.query.graphql';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { getMarkdown } from '~/rest_api';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { helpCenterState } from '~/super_sidebar/constants';
import {
  MOCK_USER_MESSAGE,
  MOCK_USER_ID,
  MOCK_RESOURCE_ID,
  MOCK_TANUKI_SUCCESS_RES,
  MOCK_TANUKI_BOT_MUTATATION_RES,
  MOCK_CHAT_CACHED_MESSAGES_RES,
} from '../mock_data';

Vue.use(Vuex);
Vue.use(VueApollo);

jest.mock('~/rest_api');
jest.mock('uuid');

describe('GitLab Duo Chat', () => {
  let wrapper;

  const actionSpies = {
    addDuoChatMessage: jest.fn(),
    setMessages: jest.fn(),
    setLoading: jest.fn(),
  };

  const subscriptionHandlerMock = jest.fn().mockResolvedValue(MOCK_TANUKI_SUCCESS_RES);
  const chatMutationHandlerMock = jest.fn().mockResolvedValue(MOCK_TANUKI_BOT_MUTATATION_RES);
  const queryHandlerMock = jest.fn().mockResolvedValue(MOCK_CHAT_CACHED_MESSAGES_RES);

  const findCallout = () => wrapper.findComponent(DuoChatCallout);

  const createComponent = ({
    initialState = {},
    propsData = { userId: MOCK_USER_ID, resourceId: MOCK_RESOURCE_ID },
    glFeatures = { duoChatBeta: false },
  } = {}) => {
    const store = new Vuex.Store({
      actions: actionSpies,
      state: {
        ...initialState,
      },
    });

    const apolloProvider = createMockApollo([
      [aiResponseSubscription, subscriptionHandlerMock],
      [chatMutation, chatMutationHandlerMock],
      [getAiMessages, queryHandlerMock],
    ]);

    wrapper = shallowMountExtended(TanukiBotChatApp, {
      store,
      apolloProvider,
      propsData,
      provide: {
        glFeatures,
      },
    });
  };

  const findGlDuoChat = () => wrapper.findComponent(GlDuoChat);

  beforeEach(() => {
    uuidv4.mockImplementation(() => '123');
    getMarkdown.mockImplementation(({ text }) => Promise.resolve({ data: { html: text } }));
  });

  it('generates unique `clientSubscriptionId` using v4', () => {
    createComponent();
    expect(uuidv4).toHaveBeenCalled();
    expect(wrapper.vm.clientSubscriptionId).toBe('123');
  });

  it('fetches the cached messages on mount', () => {
    createComponent();
    expect(queryHandlerMock).toHaveBeenCalled();
  });

  describe('rendering', () => {
    beforeEach(() => {
      createComponent();
      helpCenterState.showTanukiBotChatDrawer = true;
    });

    it('renders the DuoChat component', () => {
      expect(findGlDuoChat().exists()).toBe(true);
    });

    it.each`
      isFlagEnabled | expectedPropValue | expectedAnchorValue
      ${true}       | ${'beta'}         | ${'#beta'}
      ${false}      | ${'experiment'}   | ${'#experiment'}
    `(
      'sets correct `badge-type` and `badge-help-page-url` props on the chat compnent when feature flag is $isFlagEnabled',
      ({ isFlagEnabled, expectedPropValue, expectedAnchorValue }) => {
        createComponent({ glFeatures: { duoChatBeta: isFlagEnabled } });
        expect(findGlDuoChat().props('badgeType')).toBe(expectedPropValue);
        expect(findGlDuoChat().props('badgeHelpPageUrl')).toContain(expectedAnchorValue);
      },
    );

    it('renders the duo-chat-callout component', () => {
      createComponent();
      expect(findCallout().exists()).toBe(true);
    });
  });

  describe('events handling', () => {
    beforeEach(() => {
      createComponent();
      helpCenterState.showTanukiBotChatDrawer = true;
    });

    describe('@chat-hidden', () => {
      beforeEach(async () => {
        findGlDuoChat().vm.$emit('chat-hidden');
        await nextTick();
      });

      it('closes the chat on @chat-hidden', () => {
        expect(helpCenterState.showTanukiBotChatDrawer).toBe(false);
        expect(findGlDuoChat().exists()).toBe(false);
      });
    });

    describe('@send-chat-prompt', () => {
      it('does set loading to `true` for a message other than the reset one', () => {
        findGlDuoChat().vm.$emit('send-chat-prompt', MOCK_USER_MESSAGE.msg);
        expect(actionSpies.setLoading).toHaveBeenCalled();
      });
      it('does not set loading to `true` for a reset message', async () => {
        actionSpies.setLoading.mockReset();
        findGlDuoChat().vm.$emit('send-chat-prompt', GENIE_CHAT_RESET_MESSAGE);
        await nextTick();
        expect(actionSpies.setLoading).not.toHaveBeenCalled();
      });

      describe.each`
        resourceId          | expectedResourceId
        ${MOCK_RESOURCE_ID} | ${MOCK_RESOURCE_ID}
        ${null}             | ${MOCK_USER_ID}
      `(`with resourceId = $resourceId`, ({ resourceId, expectedResourceId }) => {
        it.each`
          isFlagEnabled | expectedMutation
          ${true}       | ${chatMutationHandlerMock}
        `(
          'calls correct GraphQL mutation with fallback to userId when input is submitted and feature flag is $isFlagEnabled',
          async ({ expectedMutation } = {}) => {
            createComponent({ propsData: { userId: MOCK_USER_ID, resourceId } });
            findGlDuoChat().vm.$emit('send-chat-prompt', MOCK_USER_MESSAGE.msg);

            await nextTick();

            expect(expectedMutation).toHaveBeenCalledWith({
              resourceId: expectedResourceId,
              question: MOCK_USER_MESSAGE.msg,
              clientSubscriptionId: '123',
            });
          },
        );

        it('once response arrives via GraphQL subscription with userId fallback calls addDuoChatMessage', () => {
          subscriptionHandlerMock.mockClear();

          createComponent({
            initialState: { loading: true },
            propsData: { userId: MOCK_USER_ID, resourceId },
          });

          expect(subscriptionHandlerMock).toHaveBeenNthCalledWith(1, {
            userId: MOCK_USER_ID,
            aiAction: 'CHAT',
            htmlResponse: true,
          });
          expect(subscriptionHandlerMock).toHaveBeenNthCalledWith(2, {
            userId: MOCK_USER_ID,
            resourceId: expectedResourceId,
            htmlResponse: false,
            clientSubscriptionId: '123',
          });
          expect(actionSpies.addDuoChatMessage).toHaveBeenCalledWith(
            expect.any(Object),
            MOCK_TANUKI_SUCCESS_RES.data.aiCompletionResponse,
          );
        });
      });
    });

    describe('@track-feedback', () => {
      let trackingSpy;

      beforeEach(() => {
        trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      });

      afterEach(() => {
        unmockTracking();
      });

      it('tracks the snowplow event on successful mutation for chat', async () => {
        createComponent();
        findGlDuoChat().vm.$emit('track-feedback', {
          feedbackChoices: ['foo', 'bar'],
          extendedTextFeedback: 'baz',
        });

        await waitForPromises();
        expect(trackingSpy).toHaveBeenCalledWith(undefined, TANUKI_BOT_TRACKING_EVENT_NAME, {
          action: 'click_button',
          label: 'response_feedback',
          property: ['foo', 'bar'],
          extra: {
            extendedFeedback: 'baz',
            prompt_location: 'after_content',
          },
        });
      });
    });
  });

  describe('Error conditions', () => {
    const errorText = 'Fancy foo';

    describe.each`
      mock                       | description
      ${subscriptionHandlerMock} | ${'subscription'}
      ${queryHandlerMock}        | ${'querying cached messages'}
    `('when $description fails', ({ mock }) => {
      beforeEach(async () => {
        mock.mockRejectedValue(new Error(errorText));
        helpCenterState.showTanukiBotChatDrawer = true;
        createComponent();
        await waitForPromises();
      });

      it('does not call addDuoChatMessage', () => {
        expect(actionSpies.addDuoChatMessage).not.toHaveBeenCalled();
        expect(findGlDuoChat().props('error')).toBe(`Error: ${errorText}`);
      });
    });

    describe('when mutation fails', () => {
      beforeEach(async () => {
        chatMutationHandlerMock.mockRejectedValue(new Error(errorText));
        helpCenterState.showTanukiBotChatDrawer = true;
        createComponent();
        await waitForPromises();
        findGlDuoChat().vm.$emit('send-chat-prompt', MOCK_USER_MESSAGE.content);
        await waitForPromises();
      });

      it('throws an error, but still calls addDuoChatMessage', () => {
        expect(actionSpies.addDuoChatMessage).toHaveBeenCalledWith(
          expect.anything(),
          expect.objectContaining({
            content: MOCK_USER_MESSAGE.content,
          }),
        );
        expect(findGlDuoChat().props('error')).toBe(`Error: ${errorText}`);
      });
    });
  });
});
