<script>
import { GlIcon, GlBadge, GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'FeatureListItem',
  components: {
    GlButton,
    GlIcon,
    GlBadge,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: true,
    },
    to: {
      type: String,
      required: true,
    },
    badgeText: {
      type: String,
      required: false,
      default: '',
    },
    actionText: {
      type: String,
      required: false,
      default: __('Set up'),
    },
  },
  featureAvatarColor: 1,
};
</script>

<template>
  <li class="gl-display-flex! gl-px-5! gl-align-items-center">
    <div class="gl-float-left gl-mr-4 gl-display-flex gl-align-items-center">
      <gl-icon name="cloud-gear" class="gl-text-gray-200 gl-mr-3" :size="16" />
    </div>
    <div
      class="gl-display-flex gl-align-items-center gl-justify-content-space-between gl-flex-grow-1"
    >
      <div class="gl-display-flex gl-flex-direction-column">
        <strong class="gl-text-gray-300">
          {{ title }}
        </strong>
        <p class="gl-line-height-normal gl-m-0 gl-text-gray-300">
          {{ description }}
        </p>
      </div>
      <div class="gl-float-right">
        <gl-badge v-if="badgeText">{{ badgeText }}</gl-badge>
        <gl-button data-testid="setup-button" :to="to">{{ actionText }}</gl-button>
      </div>
    </div>
  </li>
</template>
