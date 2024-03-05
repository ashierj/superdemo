<script>
import { GlLoadingIcon } from '@gitlab/ui';
import ComparisonChart from 'ee/analytics/dashboards/components/comparison_chart.vue';
import GroupOrProjectProvider from 'ee/analytics/dashboards/components/group_or_project_provider.vue';

export default {
  name: 'DoraChart',
  components: {
    ComparisonChart,
    GlLoadingIcon,
    GroupOrProjectProvider,
  },
  props: {
    data: {
      type: Object,
      required: true,
    },
    // Part of the visualizations API, but left unused for dora chart.
    options: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
};
</script>

<template>
  <group-or-project-provider
    #default="{ isProject, isNamespaceLoading }"
    :full-path="data.namespace"
  >
    <div v-if="isNamespaceLoading" class="gl--flex-center gl-h-full">
      <gl-loading-icon size="lg" />
    </div>
    <comparison-chart
      v-else
      :request-path="data.namespace"
      :is-project="isProject"
      :exclude-metrics="data.excludeMetrics"
      :filter-labels="data.filterLabels"
    />
  </group-or-project-provider>
</template>
