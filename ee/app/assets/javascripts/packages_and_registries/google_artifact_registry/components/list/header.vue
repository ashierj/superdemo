<script>
import { GlAlert, GlButton } from '@gitlab/ui';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';

export default {
  name: 'ListHeader',
  components: {
    GlAlert,
    GlButton,
    MetadataItem,
    TitleArea,
  },
  props: {
    data: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    showError: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    showMetadata() {
      return !this.showError;
    },
    showActions() {
      return !this.isLoading && !this.showError;
    },
  },
};
</script>

<template>
  <title-area :title="__('Google Artifact Registry')" :metadata-loading="isLoading">
    <template v-if="showActions" #right-actions>
      <gl-button
        :href="data.gcpRepositoryUrl"
        icon="external-link"
        target="_blank"
        category="primary"
        variant="default"
      >
        {{ s__('GoogleArtifactRegistry|Open in Google Cloud') }}
      </gl-button>
    </template>
    <template v-if="showMetadata" #metadata-repository>
      <metadata-item
        data-testid="repository-name"
        icon="folder"
        :text="data.repository"
        :text-tooltip="s__('GoogleArtifactRegistry|Repository name')"
        size="xl"
      />
    </template>
    <template v-if="showMetadata" #metadata-project>
      <metadata-item
        data-testid="project-id"
        icon="project"
        :text="data.project"
        :text-tooltip="s__('GoogleArtifactRegistry|Project ID')"
        size="xl"
      />
    </template>
    <gl-alert v-if="showError" variant="danger" :dismissible="false">
      {{ s__('GoogleArtifactRegistry|An error occurred while fetching the artifacts.') }}
    </gl-alert>
  </title-area>
</template>
