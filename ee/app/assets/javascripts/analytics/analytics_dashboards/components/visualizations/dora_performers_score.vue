<script>
import { GlAlert } from '@gitlab/ui';
import { DORA_PERFORMERS_SCORE_PROJECT_ERROR } from 'ee/analytics/dashboards/constants';
import DoraPerformersScore from 'ee/analytics/dashboards/components/dora_performers_score.vue';

export default {
  name: 'DoraPerformersScoreVisualization',
  components: {
    GlAlert,
    DoraPerformersScore,
  },
  props: {
    data: {
      type: Object,
      required: true,
    },
    // Part of the visualizations API, but left unused for dora performers score.
    options: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    formattedData() {
      return { namespace: this.data.namespace.requestPath };
    },
    errorMessage() {
      return this.data.namespace.isProject ? DORA_PERFORMERS_SCORE_PROJECT_ERROR : '';
    },
  },
};
</script>
<template>
  <div>
    <gl-alert v-if="errorMessage" variant="danger" :dismissible="false">
      {{ errorMessage }}
    </gl-alert>
    <dora-performers-score v-else :data="formattedData" />
  </div>
</template>
