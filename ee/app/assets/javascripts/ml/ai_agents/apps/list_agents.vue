<script>
import { GlBadge, GlButton } from '@gitlab/ui';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import AgentList from '../components/agent_list.vue';

export default {
  name: 'ListAiAgents',
  components: {
    TitleArea,
    AgentList,
    GlBadge,
    GlButton,
  },
  provide() {
    return {
      projectPath: this.projectPath,
    };
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    createAgentPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      errorMessage: undefined,
    };
  },
  helpPagePath: helpPagePath('policy/experiment-beta-support', { anchor: 'experiment' }),
};
</script>

<template>
  <div>
    <title-area>
      <template #title>
        <div class="gl-flex-grow-1 gl-display-flex gl-align-items-center">
          <span>{{ s__('AIAgents|AI Agents') }}</span>
          <gl-badge variant="neutral" class="gl-mx-4" size="lg" :href="$options.helpPagePath">
            {{ __('Experiment') }}
          </gl-badge>
        </div>
      </template>
      <template #right-actions>
        <gl-button :href="createAgentPath">{{ s__('AIAgents|Create agent') }}</gl-button>
      </template>
    </title-area>

    <agent-list :create-agent-path="createAgentPath" />
  </div>
</template>
