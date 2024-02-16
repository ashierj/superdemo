<script>
import { GlAlert, GlButton } from '@gitlab/ui';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

export default {
  name: 'DetailsHeader',
  components: {
    ClipboardButton,
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
  <title-area :title="data.title" :metadata-loading="isLoading">
    <template v-if="showActions" #right-actions>
      <gl-button
        :href="data.artifactRegistryImageUrl"
        icon="external-link"
        target="_blank"
        category="primary"
        variant="default"
      >
        {{ s__('GoogleArtifactRegistry|Open in Google Cloud') }}
      </gl-button>
    </template>
    <template v-if="showMetadata" #metadata-uri>
      <metadata-item data-testid="uri" :text="data.uri" size="l" />
      <clipboard-button
        :title="s__('GoogleArtifactRegistry|Copy image URI')"
        :text="data.uri"
        category="tertiary"
      />
    </template>
    <gl-alert v-if="showError" variant="danger" :dismissible="false">
      {{ s__('GoogleArtifactRegistry|An error occurred while fetching the artifact details.') }}
    </gl-alert>
  </title-area>
</template>
