<script>
import ObservabilityContainer from '~/observability/components/observability_container.vue';

export default {
  components: {
    ObservabilityContainer,
  },
  props: {
    oauthUrl: {
      type: String,
      required: true,
    },
    tracingUrl: {
      type: String,
      required: true,
    },
    servicesUrl: {
      type: String,
      required: true,
    },
    provisioningUrl: {
      type: String,
      required: true,
    },
    operationsUrl: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <observability-container
    :oauth-url="oauthUrl"
    :tracing-url="tracingUrl"
    :services-url="servicesUrl"
    :provisioning-url="provisioningUrl"
    :operations-url="operationsUrl"
  >
    <template #default>
      <!-- TODO Implement List UI -->
    </template>
  </observability-container>
</template>
