<script>
import ProvisionedObservabilityContainer from '~/observability/components/provisioned_observability_container.vue';

export default {
  components: {
    ProvisionedObservabilityContainer,
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
    <template #default>
      <!-- TODO Implement List UI -->
    </template>
  </provisioned-observability-container>
</template>
