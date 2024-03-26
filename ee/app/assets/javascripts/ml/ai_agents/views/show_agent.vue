<script>
import { GlExperimentBadge, GlDuoChat, GlEmptyState, GlLoadingIcon, GlButton } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { renderMarkdown } from '~/notes/utils';
import { TYPENAME_AI_AGENT, TYPENAME_AI_AGENT_VERSION } from 'ee/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import chatMutation from 'ee/ai/graphql/chat.mutation.graphql';
import { GENIE_CHAT_MODEL_ROLES } from 'ee/ai/constants';
import { ROUTE_AGENT_SETTINGS, I18N_DEFAULT_NOT_FOUND_ERROR } from 'ee/ml/ai_agents/constants';
import getLatestAiAgentVersion from 'ee/ml/ai_agents/graphql/queries/get_latest_ai_agent_version.query.graphql';

export default {
  name: 'ShowAiAgent',
  // Needed to override the default predefined prompts
  predefinedPrompts: [],
  components: {
    TitleArea,
    GlExperimentBadge,
    GlDuoChat,
    GlEmptyState,
    GlLoadingIcon,
    GlButton,
  },
  ROUTE_AGENT_SETTINGS,
  I18N_DEFAULT_NOT_FOUND_ERROR,
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
    latestAgentVersion: {
      query: getLatestAiAgentVersion,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data.project?.aiAgent ?? {};
      },
      error(error) {
        this.errorMessage = error.message;
        Sentry.captureException(error);
      },
    },
    // https://apollo.vuejs.org/guide-option/subscriptions.html#simple-subscription
    $subscribe: {
      aiCompletionResponse: {
        query: aiResponseSubscription,
        variables() {
          return {
            userId: this.userId,
            agentVersionId: this.agentVersionGraphQLId,
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
      errorMessage: '',
      error: null,
      messages: [],
      isLoading: false,
    };
  },
  computed: {
    isAgentLoading() {
      return this.$apollo.queries.latestAgentVersion.loading;
    },
    queryVariables() {
      return {
        fullPath: this.projectPath,
        agentId: convertToGraphQLId(TYPENAME_AI_AGENT, this.$route.params.agentId),
      };
    },
    agentVersionGraphQLId() {
      return convertToGraphQLId(TYPENAME_AI_AGENT_VERSION, this.$route.params.agentId);
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
            agentVersionId: this.agentVersionGraphQLId,
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
    <gl-loading-icon v-if="isAgentLoading" size="lg" class="gl-my-5" />

    <gl-empty-state
      v-else-if="latestAgentVersion && Object.keys(latestAgentVersion).length === 0"
      :title="$options.I18N_DEFAULT_NOT_FOUND_ERROR"
    />

    <div v-else>
      <title-area>
        <template #title>
          <div class="gl-flex-grow-1 gl-display-flex gl-align-items-center">
            <span>{{ latestAgentVersion.name }}</span>
            <gl-experiment-badge />
          </div>
        </template>

        <template #right-actions>
          <gl-button data-testid="settings-button" :to="{ name: $options.ROUTE_AGENT_SETTINGS }">{{
            s__('AIAgent|Settings')
          }}</gl-button>
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
  </div>
</template>
