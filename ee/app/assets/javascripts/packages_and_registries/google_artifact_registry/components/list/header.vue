<script>
import { GlAlert, GlButton, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
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
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['settingsPath'],
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
  i18n: {
    settingsText: s__('GoogleArtifactRegistry|Configure in settings'),
  },
};
</script>

<template>
  <title-area :title="__('Google Artifact Registry')" :metadata-loading="isLoading">
    <template v-if="showActions" #right-actions>
      <div class="gl-display-flex gl-gap-3">
        <gl-button
          :href="data.gcpRepositoryUrl"
          icon="external-link"
          target="_blank"
          category="primary"
          variant="default"
        >
          {{ s__('GoogleArtifactRegistry|Open in Google Cloud') }}
        </gl-button>
        <gl-button
          v-if="settingsPath"
          v-gl-tooltip="$options.i18n.settingsText"
          icon="settings"
          data-testid="settings-link"
          :href="settingsPath"
          :aria-label="$options.i18n.settingsText"
        />
      </div>
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
        :text="data.projectId"
        :text-tooltip="s__('GoogleArtifactRegistry|Project ID')"
        size="xl"
      />
    </template>
    <gl-alert v-if="showError" variant="danger" :dismissible="false">
      {{ s__('GoogleArtifactRegistry|An error occurred while fetching the artifacts.') }}
    </gl-alert>
  </title-area>
</template>
