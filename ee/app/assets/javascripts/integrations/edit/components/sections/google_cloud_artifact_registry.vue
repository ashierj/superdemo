<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import { GlButton } from '@gitlab/ui';
import Configuration from '~/integrations/edit/components/sections/configuration.vue';
import Connection from '~/integrations/edit/components/sections/connection.vue';
import ConfigurationInstructions from 'ee/integrations/edit/components/google_cloud_artifact_registry/configuration_instructions.vue';
import EmptyState from 'ee/integrations/edit/components/google_cloud_artifact_registry/empty_state.vue';

const PROJECT_ID_FIELD_NAME = 'artifact_registry_project_id';

export default {
  name: 'IntegrationSectionGoogleCloudArtifactRegistry',
  components: {
    Configuration,
    ConfigurationInstructions,
    Connection,
    EmptyState,
    GlButton,
  },
  props: {
    isValidated: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      googleCloudProjectId: null,
    };
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
    editable() {
      return this.propsSource.editable;
    },
    workloadIdentityFederationPath() {
      return (
        this.propsSource.googleCloudArtifactRegistryProps?.workloadIdentityFederationPath ?? '#'
      );
    },
    propsSourceGoogleCloudProjectId() {
      return (
        this.propsSource.fields.find((field) => field.name === PROJECT_ID_FIELD_NAME)?.value ?? ''
      );
    },
    derivedGoogleCloudProjectId() {
      if (this.googleCloudProjectId === null) {
        return this.propsSourceGoogleCloudProjectId;
      }
      return this.googleCloudProjectId;
    },
  },
  methods: {
    updateGoogleCloudProjectId({ value, field }) {
      if (field.name === PROJECT_ID_FIELD_NAME) {
        this.googleCloudProjectId = value;
      }
    },
  },
};
</script>

<template>
  <div v-if="editable">
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
    <connection @toggle-integration-active="$emit('toggle-integration-active', $event)" />
    <h3 class="gl-mt-0">{{ s__('GoogleArtifactRegistry|Repository') }}</h3>
    <configuration
      :fields="dynamicFields"
      :is-validated="isValidated"
      class="gl-form-input-xl"
      @update="updateGoogleCloudProjectId"
    />
    <hr />
    <configuration-instructions :id="derivedGoogleCloudProjectId" />
  </div>
  <empty-state v-else :path="workloadIdentityFederationPath" />
</template>
