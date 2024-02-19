<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import { GlButton } from '@gitlab/ui';
import Connection from '~/integrations/edit/components/sections/connection.vue';

export default {
  name: 'IntegrationSectionGoogleCloudArtifactRegistry',
  components: {
    Connection,
    GlButton,
  },
  computed: {
    ...mapGetters(['propsSource']),
    dynamicFields() {
      return this.propsSource.fields;
    },
    artifactRegistryPath() {
      return this.propsSource.googleCloudArtifactRegistryProps?.artifactRegistryPath;
    },
    operating() {
      return this.propsSource.operating;
    },
  },
};
</script>

<template>
  <div>
    <template v-if="operating">
      <div class="gl-display-flex gl-gap-3">
        <gl-button
          :href="artifactRegistryPath"
          icon="deployments"
          category="primary"
          variant="default"
        >
          {{ s__('GoogleArtifactRegistry|View artifacts') }}
        </gl-button>
      </div>
      <hr />
    </template>
    <connection :fields="dynamicFields" />
  </div>
</template>
