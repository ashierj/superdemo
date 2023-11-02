<script>
import ProvisionedObservabilityContainer from '~/observability/components/provisioned_observability_container.vue';
import MetricsList from './list/metrics_list.vue';

export default {
  components: {
    ProvisionedObservabilityContainer,
    MetricsList,
  },
  props: {
    apiConfig: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <provisioned-observability-container :api-config="apiConfig">
    <template #default="{ observabilityClient }">
      <metrics-list :observability-client="observabilityClient" />
    </template>
  </provisioned-observability-container>
</template>
