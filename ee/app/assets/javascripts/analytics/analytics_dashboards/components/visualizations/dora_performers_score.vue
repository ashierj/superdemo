<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { DORA_PERFORMERS_SCORE_PROJECT_ERROR } from 'ee/analytics/dashboards/constants';
import DoraPerformersScoreChart from 'ee/analytics/dashboards/components/dora_performers_score_chart.vue';
import GroupOrProjectProvider from 'ee/analytics/dashboards/components/group_or_project_provider.vue';

export default {
  name: 'DoraPerformersScoreVisualization',
  components: {
    DoraPerformersScoreChart,
    GlLoadingIcon,
    GroupOrProjectProvider,
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
    fullPath() {
      return this.data?.namespace;
    },
  },
  methods: {
    handleResolveNamespace({ isProject = false }) {
      if (isProject) {
        this.$emit('error', { error: DORA_PERFORMERS_SCORE_PROJECT_ERROR, canRetry: false });
      }
    },
  },
};
</script>
<template>
  <group-or-project-provider
    #default="{ isNamespaceLoading, isProject }"
    :full-path="fullPath"
    @done="handleResolveNamespace"
    @error="(errorMsg) => $emit('error', errorMsg)"
  >
    <div v-if="isNamespaceLoading" class="gl--flex-center gl-h-full">
      <gl-loading-icon size="lg" />
    </div>
    <dora-performers-score-chart
      v-else-if="!isNamespaceLoading && !isProject"
      :data="data"
      @error="$emit('error', arguments[0])"
    />
  </group-or-project-provider>
</template>
