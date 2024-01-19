<script>
import { DORA_PERFORMERS_SCORE_PROJECT_ERROR } from 'ee/analytics/dashboards/constants';
import DoraPerformersScoreChart from 'ee/analytics/dashboards/components/dora_performers_score_chart.vue';

export default {
  name: 'DoraPerformersScoreVisualization',
  components: {
    DoraPerformersScoreChart,
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
    isProject() {
      return this.data.namespace.isProject;
    },
    formattedData() {
      return { namespace: this.data.namespace.requestPath };
    },
  },
  mounted() {
    if (this.isProject) {
      this.$emit('error', { error: DORA_PERFORMERS_SCORE_PROJECT_ERROR, canRetry: false });
    }
  },
};
</script>
<template>
  <dora-performers-score-chart
    v-if="!isProject"
    :data="formattedData"
    @error="$emit('error', arguments[0])"
  />
</template>
