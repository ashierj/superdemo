<script>
import { GlExperimentBadge } from '@gitlab/ui';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { sprintf, s__ } from '~/locale';

export default {
  name: 'ShowAiAgent',
  components: {
    TitleArea,
    GlExperimentBadge,
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
    agentId: {
      type: String,
      required: true,
    },
  },
  computed: {
    title() {
      return sprintf(s__('AIAgent|AI Agent: %{agentId}'), { agentId: this.agentId });
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
  </div>
</template>
