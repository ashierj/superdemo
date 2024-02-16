<script>
import { GlBadge, GlSkeletonLoader, GlTruncate } from '@gitlab/ui';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { formatDate } from '~/lib/utils/datetime/date_format_utility';
import { s__ } from '~/locale';

export default {
  name: 'ImageDetails',
  components: {
    GlBadge,
    GlSkeletonLoader,
    GlTruncate,
  },
  props: {
    data: {
      type: Object,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    formattedSize() {
      const { imageSizeBytes } = this.data;
      return numberToHumanSize(Number(imageSizeBytes));
    },
    buildTime() {
      return this.data.buildTime ? formatDate(this.data.buildTime) : '';
    },
    uploadTime() {
      return this.data.uploadTime ? formatDate(this.data.uploadTime) : '';
    },
    updateTime() {
      return this.data.updateTime ? formatDate(this.data.updateTime) : '';
    },
    rows() {
      return Object.entries({
        mediaType: {
          label: s__('GoogleArtifactRegistry|Media type'),
          value: this.data.mediaType,
        },
        project: {
          label: s__('GoogleArtifactRegistry|Project'),
          value: this.data.project,
        },
        location: {
          label: s__('GoogleArtifactRegistry|Location'),
          value: this.data.location,
        },
        repository: {
          label: s__('GoogleArtifactRegistry|Repository'),
          value: this.data.repository,
        },
        image: {
          label: s__('GoogleArtifactRegistry|Image'),
          value: this.data.image,
        },
        digest: {
          label: s__('GoogleArtifactRegistry|Digest'),
          value: this.data.digest,
        },
        imageSizeBytes: {
          label: s__('GoogleArtifactRegistry|Virtual size'),
          value: this.formattedSize,
        },
        buildTime: {
          label: s__('GoogleArtifactRegistry|Built'),
          value: this.buildTime,
        },
        uploadTime: {
          label: s__('GoogleArtifactRegistry|Created'),
          value: this.uploadTime,
        },
        updateTime: {
          label: s__('GoogleArtifactRegistry|Updated'),
          value: this.updateTime,
        },
      });
    },
  },
};
</script>

<template>
  <gl-skeleton-loader v-if="isLoading" :lines="11" />
  <ul v-else class="gl-list-style-none gl-pl-0" data-testid="image-details">
    <li
      v-for="[key, row] in rows"
      :key="key"
      class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row gl-pb-2"
    >
      <span class="gl-font-weight-bold gl-md-flex-basis-13">{{ row.label }}</span>
      <span class="gl-word-break-word" :data-testid="key">{{ row.value }}</span>
    </li>
    <li class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row">
      <span class="gl-font-weight-bold gl-md-flex-basis-13">{{
        s__('GoogleArtifactRegistry|Tags')
      }}</span>
      <span class="gl-display-flex gl-gap-2 gl-flex-wrap" data-testid="tags">
        <gl-badge v-for="tag in data.tags" :key="tag" class="gl-max-w-12">
          <gl-truncate class="gl-max-w-80p" :text="tag" :with-tooltip="true" />
        </gl-badge>
      </span>
    </li>
  </ul>
</template>
