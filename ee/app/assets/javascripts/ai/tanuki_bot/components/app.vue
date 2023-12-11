<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import { GlDuoChat } from '@gitlab/ui';
import { v4 as uuidv4 } from 'uuid';
import { __, s__ } from '~/locale';
import { renderMarkdown } from '~/notes/utils';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { helpPagePath } from '~/helpers/help_page_helper';
import { helpCenterState } from '~/super_sidebar/constants';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import DuoChatCallout from 'ee/ai/components/global_callout/duo_chat_callout.vue';
import getAiMessages from 'ee/ai/graphql/get_ai_messages.query.graphql';
import chatMutation from 'ee/ai/graphql/chat.mutation.graphql';
import Tracking from '~/tracking';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { i18n, GENIE_CHAT_RESET_MESSAGE, GENIE_CHAT_CLEAN_MESSAGE } from 'ee/ai/constants';
import { TANUKI_BOT_TRACKING_EVENT_NAME } from '../constants';

export default {
  name: 'TanukiBotChatApp',
  i18n: {
    gitlabChat: s__('TanukiBot|GitLab Duo Chat'),
    giveFeedback: s__('TanukiBot|Give feedback'),
    source: __('Source'),
    experiment: __('Experiment'),
    askAQuestion: s__('TanukiBot|Ask a question about GitLab'),
    exampleQuestion: s__('TanukiBot|For example, %{linkStart}what is a fork%{linkEnd}?'),
    whatIsAForkQuestion: s__('TanukiBot|What is a fork?'),
    GENIE_CHAT_LEGAL_GENERATED_BY_AI: i18n.GENIE_CHAT_LEGAL_GENERATED_BY_AI,
    predefinedPrompts: [
      __('How do I change my password in GitLab?'),
      __('How do I fork a project?'),
      __('How do I clone a repository?'),
      __('How do I create a template?'),
    ],
  },
  helpPagePath: helpPagePath('policy/experiment-beta-support', { anchor: 'beta' }),
  components: {
    GlDuoChat,
    DuoChatCallout,
  },
  mixins: [Tracking.mixin(), glFeatureFlagsMixin()],
  provide() {
    return {
      renderMarkdown,
      renderGFM,
    };
  },
  props: {
    userId: {
      type: String,
      required: true,
    },
    resourceId: {
      type: String,
      required: false,
      default: null,
    },
  },
  apollo: {
    // https://apollo.vuejs.org/guide/apollo/subscriptions.html#simple-subscription
    $subscribe: {
      aiCompletionResponse: {
        query: aiResponseSubscription,
        variables() {
          return {
            userId: this.userId,
            aiAction: 'CHAT',
          };
        },
        result({ data }) {
          this.addDuoChatMessage(data?.aiCompletionResponse);
        },
        error(err) {
          this.error = err.toString();
        },
      },
      aiCompletionResponseStream: {
        query: aiResponseSubscription,
        variables() {
          return {
            userId: this.userId,
            resourceId: this.resourceId || this.userId,
            clientSubscriptionId: this.clientSubscriptionId,
            htmlResponse: false,
          };
        },
        result({ data }) {
          this.addDuoChatMessage(data?.aiCompletionResponse);
        },
        error(err) {
          this.error = err.toString();
        },
      },
    },
    aiMessages: {
      query: getAiMessages,
      result({ data }) {
        if (data?.aiMessages?.nodes) {
          this.setMessages(data.aiMessages.nodes);
        }
      },
      error(err) {
        this.error = err.toString();
      },
    },
  },
  data() {
    return {
      helpCenterState,
      clientSubscriptionId: uuidv4(),
      toolName: i18n.GITLAB_DUO,
      error: '',
    };
  },
  computed: {
    ...mapState(['loading', 'messages']),
    shouldRenderCallout() {
      return this.glFeatures.duoChatCallout;
    },
  },
  methods: {
    ...mapActions(['addDuoChatMessage', 'setMessages', 'setLoading']),
    onSendChatPrompt(question) {
      if (![GENIE_CHAT_CLEAN_MESSAGE, GENIE_CHAT_RESET_MESSAGE].includes(question)) {
        this.setLoading();
      }
      this.$apollo
        .mutate({
          mutation: chatMutation,
          variables: {
            question,
            resourceId: this.resourceId || this.userId,
            clientSubscriptionId: this.clientSubscriptionId,
          },
        })
        .then(({ data: { aiAction = {} } = {} }) => {
          if (![GENIE_CHAT_CLEAN_MESSAGE, GENIE_CHAT_RESET_MESSAGE].includes(question)) {
            this.track('submit_gitlab_duo_question', {
              property: aiAction.requestId,
            });
          }
          if (question === GENIE_CHAT_CLEAN_MESSAGE) {
            this.$apollo.queries.aiMessages.refetch();
          } else {
            this.addDuoChatMessage({
              ...aiAction,
              content: question,
            });
          }
        })
        .catch((err) => {
          this.error = err.toString();
          this.addDuoChatMessage({
            content: question,
          });
          this.setLoading(false);
        });
    },
    onChatClose() {
      this.helpCenterState.showTanukiBotChatDrawer = false;
    },
    onCalloutDismissed() {
      this.helpCenterState.showTanukiBotChatDrawer = true;
    },
    onTrackFeedback({ extendedTextFeedback, feedbackChoices } = {}) {
      this.track(TANUKI_BOT_TRACKING_EVENT_NAME, {
        action: 'click_button',
        label: 'response_feedback',
        property: feedbackChoices,
        extra: {
          extendedFeedback: extendedTextFeedback,
          prompt_location: 'after_content',
        },
      });
    },
  },
};
</script>

<template>
  <div>
    <gl-duo-chat
      v-if="helpCenterState.showTanukiBotChatDrawer"
      :title="$options.i18n.gitlabChat"
      :messages="messages"
      :error="error"
      :is-loading="loading"
      :predefined-prompts="$options.i18n.predefinedPrompts"
      badge-type="beta"
      :badge-help-page-url="$options.helpPagePath"
      :tool-name="toolName"
      class="gl-z-index-9999"
      @send-chat-prompt="onSendChatPrompt"
      @chat-hidden="onChatClose"
      @track-feedback="onTrackFeedback"
    />
    <duo-chat-callout v-if="shouldRenderCallout" @callout-dismissed="onCalloutDismissed" />
  </div>
</template>
