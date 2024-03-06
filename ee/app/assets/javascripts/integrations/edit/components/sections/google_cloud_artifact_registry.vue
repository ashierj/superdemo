<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import { GlButton } from '@gitlab/ui';
import Configuration from '~/integrations/edit/components/sections/configuration.vue';
import Connection from '~/integrations/edit/components/sections/connection.vue';
import ConfigurationInstructions from 'ee/integrations/edit/components/google_cloud_artifact_registry/configuration_instructions.vue';

export default {
  name: 'IntegrationSectionGoogleCloudArtifactRegistry',
  components: {
    Configuration,
    Connection,
    ConfigurationInstructions,
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
    <connection />
    <h3 class="gl-mt-0">{{ s__('GoogleArtifactRegistry|Repository') }}</h3>
    <configuration :fields="dynamicFields" class="gl-form-input-xl" />
    <hr />
    <configuration-instructions />
  </div>
</template>
