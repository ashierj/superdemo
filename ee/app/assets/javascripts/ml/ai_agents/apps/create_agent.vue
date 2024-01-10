<script>
import { GlExperimentBadge } from '@gitlab/ui';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  name: 'CreateAiAgent',
  components: {
    TitleArea,
    GlExperimentBadge,
  },
  props: {
    projectPath: {
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
  <title-area>
    <template #title>
      <div class="gl-flex-grow-1 gl-display-flex gl-align-items-center">
        <span>{{ s__('AIAgents|New agent') }}</span>
        <gl-experiment-badge />
      </div>
    </template>
  </title-area>
</template>
