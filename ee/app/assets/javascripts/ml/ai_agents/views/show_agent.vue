<script>
import { GlExperimentBadge, GlDuoChat } from '@gitlab/ui';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { renderMarkdown } from '~/notes/utils';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { sprintf, s__ } from '~/locale';
import { GENIE_CHAT_MODEL_ROLES } from 'ee/ai/constants';
import chatMutation from 'ee/ai/graphql/chat.mutation.graphql';

export default {
  name: 'ShowAiAgent',
  // Needed to override the default predefined prompts
  predefinedPrompts: [],
  components: {
    TitleArea,
    GlExperimentBadge,
    GlDuoChat,
  },
  provide() {
    return {
      projectPath: this.projectPath,
      userId: this.userId,
      renderMarkdown,
      renderGFM,
    };
  },
  inject: ['projectPath', 'userId'],
  apollo: {
    // https://apollo.vuejs.org/guide-option/subscriptions.html#simple-subscription
    $subscribe: {
      aiCompletionResponse: {
        query: aiResponseSubscription,
        variables() {
          return {
            userId: this.userId,
            agentVersionId: `gid://gitlab/Ai::AgentVersion/${this.$route.params.agentId}`,
            aiAction: 'CHAT',
          };
        },
        result({ data }) {
          const response = data?.aiCompletionResponse;

          if (!response) {
            return;
          }

          this.messages.push(response);

          if (response.role.toLowerCase() === GENIE_CHAT_MODEL_ROLES.assistant) {
            this.isLoading = false;
          }
        },
        error(err) {
          this.error = err.toString();
        },
      },
    },
  },
  data() {
    return {
      error: null,
      messages: [],
      isLoading: false,
    };
  },
  computed: {
    title() {
      return sprintf(s__('AIAgent|AI Agent: %{agentId}'), { agentId: this.$route.params.agentId });
    },
  },
  methods: {
    onSendChatPrompt(question = '') {
      this.isLoading = true;

      this.$apollo
        .mutate({
          mutation: chatMutation,
          variables: {
            question,
            resourceId: this.userId,
            agentVersionId: `gid://gitlab/Ai::AgentVersion/${this.$route.params.agentId}`,
          },
        })
        .then(() => {
          // we add the user message in the aiCompletionResponse subscription
          this.isLoading = true;
        })
        .catch((err) => {
          this.error = err.toString();
          this.isLoading = false;
        });
    },
  },
};
</script>

<template>
  <div>
    <title-area>
      <template #title>
        <div class="gl-flex-grow-1 gl-display-flex gl-align-items-center">
          <span>{{ title }}</span>
          <gl-experiment-badge />
        </div>
      </template>
    </title-area>

    <gl-duo-chat
      :messages="messages"
      :error="error"
      :is-loading="isLoading"
      :predefined-prompts="$options.predefinedPrompts"
      :tool-name="s__('AIAgent|Agent')"
      class="ai-agent-chat gl-w-full! gl-static gl-border-r gl-border-transparent"
      :empty-state-title="s__('AIAgent|Try out your agent')"
      :empty-state-description="
        s__('AIAgent|Your agent\'s system prompt will be applied to the chat input.')
      "
      :chat-prompt-placeholder="s__('AIAgent|Ask your agent')"
      :show-header="false"
      @send-chat-prompt="onSendChatPrompt"
    />
  </div>
</template>
