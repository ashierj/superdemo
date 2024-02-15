<script>
import { GlBadge } from '@gitlab/ui';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import AgentList from '../components/agent_list.vue';
import { ROUTE_NEW_AGENT } from '../constants';

export default {
  name: 'ListAiAgents',
  components: {
    TitleArea,
    AgentList,
    GlBadge,
  },
  provide() {
    return {
      projectPath: this.projectPath,
    };
  },
  inject: ['projectPath'],
  data() {
    return {
      errorMessage: undefined,
    };
  },
  helpPagePath: helpPagePath('policy/experiment-beta-support', { anchor: 'experiment' }),
  ROUTE_NEW_AGENT,
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
        <router-link
          :to="{ name: $options.ROUTE_NEW_AGENT }"
          class="btn btn-confirm btn-md gl-button"
        >
          {{ s__('AIAgents|Create agent') }}
        </router-link>
      </template>
    </title-area>

    <agent-list />
  </div>
</template>
