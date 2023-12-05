<script>
import ObservabilityContainer from '~/observability/components/observability_container.vue';
import MetricsDetails from './details/metrics_details.vue';

export default {
  components: {
    ObservabilityContainer,
    MetricsDetails,
  },
  props: {
    metricId: {
      type: String,
      required: true,
    },
    metricType: {
      type: String,
      required: true,
    },
    metricsIndexUrl: {
      required: true,
      type: String,
    },
    apiConfig: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <observability-container :api-config="apiConfig">
    <template #default="{ observabilityClient }">
      <metrics-details
        :metric-id="metricId"
        :metric-type="metricType"
        :metrics-index-url="metricsIndexUrl"
        :observability-client="observabilityClient"
      />
    </template>
  </observability-container>
</template>
