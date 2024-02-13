<script>
import {
  GlExperimentBadge,
  GlForm,
  GlFormInput,
  GlFormGroup,
  GlButton,
  GlAlert,
  GlFormTextarea,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import createAiAgent from '../graphql/mutations/create_ai_agent.mutation.graphql';

export default {
  name: 'CreateAiAgent',
  components: {
    TitleArea,
    GlExperimentBadge,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlButton,
    GlAlert,
  },
  inject: ['projectPath'],
  data() {
    return {
      errorMessage: undefined,
      agentName: '',
      agentPrompt: '',
    };
  },
  methods: {
    async createAgent() {
      this.errorMessage = '';
      try {
        const variables = {
          projectPath: this.projectPath,
          name: this.agentName,
          prompt: this.agentPrompt,
        };

        const { data } = await this.$apollo.mutate({
          mutation: createAiAgent,
          variables,
        });

        const [error] = data?.aiAgentCreate?.errors || [];

        if (error) {
          this.errorMessage = data.aiAgentCreate.errors.join(', ');
        } else {
          this.$router.push({
            name: 'show',
            params: { agentId: data?.aiAgentCreate?.agent?.routeId },
          });
        }
      } catch (error) {
        Sentry.captureException(error);
        this.errorMessage = s__('AIAgents|An error has occurred when saving the agent.');
      }
    },
  },
  helpPagePath: helpPagePath('policy/experiment-beta-support', { anchor: 'experiment' }),
};
</script>

<template>
  <div>
    <title-area>
      <template #title>
        <div class="gl-flex-grow-1 gl-display-flex gl-align-items-center">
          <span>{{ s__('AIAgents|New agent') }}</span>
          <gl-experiment-badge />
        </div>
      </template>
    </title-area>

    <gl-alert v-if="errorMessage" :dismissible="false" variant="danger" class="gl-mb-3">
      {{ errorMessage }}
    </gl-alert>

    <gl-form @submit.prevent="createAgent">
      <gl-form-group :label="s__('AIAgents|Agent name')">
        <gl-form-input v-model="agentName" data-testid="agent-name" />
      </gl-form-group>

      <gl-form-group :label="__('Prompt')" optional>
        <gl-form-textarea v-model="agentPrompt" />
      </gl-form-group>

      <gl-button type="submit" variant="confirm" class="js-no-auto-disable">{{
        s__('AIAgents|Create agent')
      }}</gl-button>
    </gl-form>
  </div>
</template>
