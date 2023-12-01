<script>
import ProvisionedObservabilityContainer from '~/observability/components/provisioned_observability_container.vue';
import TracingList from './list/tracing_list.vue';

export default {
  components: {
    ProvisionedObservabilityContainer,
    TracingList,
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
      <tracing-list :observability-client="observabilityClient" />
    </template>
  </provisioned-observability-container>
</template>
