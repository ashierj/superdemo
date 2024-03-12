<script>
import { GlExperimentBadge, GlLoadingIcon, GlEmptyState, GlAlert } from '@gitlab/ui';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import getLatestAiAgentVersion from '../graphql/queries/get_latest_ai_agent_version.query.graphql';
import AgentForm from '../components/agent_form.vue';
import updateAiAgent from '../graphql/mutations/update_ai_agent.mutation.graphql';
import {
  I18N_UPDATE_AGENT,
  I18N_DEFAULT_SAVE_ERROR,
  I18N_DEFAULT_NOT_FOUND_ERROR,
  I18N_EDIT_AGENT,
} from '../constants';

export default {
  name: 'EditAiAgent',
  components: {
    TitleArea,
    GlExperimentBadge,
    GlLoadingIcon,
    AgentForm,
    GlEmptyState,
    GlAlert,
  },
  I18N_UPDATE_AGENT,
  I18N_DEFAULT_SAVE_ERROR,
  I18N_DEFAULT_NOT_FOUND_ERROR,
  I18N_EDIT_AGENT,
  inject: ['projectPath'],
  data() {
    return {
      errorMessage: '',
      loading: false,
    };
  },
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
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.latestAgentVersion.loading;
    },
    queryVariables() {
      return {
        fullPath: this.projectPath,
        agentId: `gid://gitlab/Ai::Agent/${this.$route.params.agentId}`,
      };
    },
    agentVersionNotFound() {
      return this.latestAgentVersion && Object.keys(this.latestAgentVersion).length === 0;
    },
  },
  methods: {
    async updateAgent(requestData) {
      this.errorMessage = '';
      this.loading = true;
      try {
        const { data } = await this.$apollo.mutate({
          mutation: updateAiAgent,
          variables: requestData,
        });

        this.loading = false;

        const [error] = data?.aiAgentUpdate?.errors || [];

        if (error) {
          this.errorMessage = data.aiAgentUpdate.errors.join(', ');
        } else {
          this.$router.push({
            name: 'show',
            params: { agentId: data?.aiAgentUpdate?.agent?.routeId },
          });
        }
      } catch (error) {
        Sentry.captureException(error);
        this.errorMessage = this.$options.I18N_DEFAULT_SAVE_ERROR;
        this.loading = false;
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="isLoading" size="lg" class="gl-my-5" />

    <gl-alert v-else-if="errorMessage" :dismissible="false" variant="danger" class="gl-mb-3">
      {{ errorMessage }}
    </gl-alert>

    <gl-empty-state
      v-else-if="agentVersionNotFound"
      :title="$options.I18N_DEFAULT_NOT_FOUND_ERROR"
    />

    <div v-else>
      <title-area>
        <template #title>
          <div class="gl-flex-grow-1 gl-display-flex gl-align-items-center">
            <span>{{ s__('AIAgents|Agent Settings') }}</span>
            <gl-experiment-badge />
          </div>
        </template>
      </title-area>

      <p class="gl-text-secondary">
        {{ s__('AIAgents|Update the name and prompt for this agent.') }}
      </p>

      <agent-form
        :project-path="projectPath"
        :agent-version="latestAgentVersion"
        :agent-name-value="latestAgentVersion.name"
        :agent-prompt-value="latestAgentVersion.latestVersion.prompt"
        :button-label="$options.I18N_UPDATE_AGENT"
        :error-message="errorMessage"
        :loading="loading"
        @submit="updateAgent"
      />
    </div>
  </div>
</template>
