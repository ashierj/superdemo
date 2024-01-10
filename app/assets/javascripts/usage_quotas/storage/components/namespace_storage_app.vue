<script>
import { GlAlert } from '@gitlab/ui';

export default {
  name: 'NamespaceStorageApp',
  components: {
    GlAlert,
  },
  props: {
    namespaceLoadingError: {
      type: Boolean,
      required: false,
      default: false,
    },
    projectsLoadingError: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>
<template>
  <div>
    <gl-alert
      v-if="namespaceLoadingError || projectsLoadingError"
      variant="danger"
      :dismissible="false"
      class="gl-mt-4"
    >
      {{
        s__(
          'UsageQuota|An error occured while loading the storage usage details. Please refresh the page to try again.',
        )
      }}
    </gl-alert>
    <slot name="ee-storage-app"></slot>
  </div>
</template>
