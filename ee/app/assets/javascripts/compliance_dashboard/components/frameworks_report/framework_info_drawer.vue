<script>
import { GlDrawer, GlButton, GlLabel } from '@gitlab/ui';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';

export default {
  name: 'FrameworkInfoDrawer',
  components: {
    GlDrawer,
    GlButton,
    GlLabel,
  },
  props: {
    framework: {
      type: Object,
      required: false,
      default: null,
    },
  },
  emits: ['edit', 'close'],
  computed: {
    showDrawer() {
      return Boolean(this.framework);
    },
    getContentWrapperHeight() {
      return getContentWrapperHeight();
    },
    frameworkSettingsPath() {
      return this.framework.webUrl;
    },
    defaultFramework() {
      return Boolean(this.framework.default);
    },
  },
  DRAWER_Z_INDEX,
};
</script>

<template>
  <gl-drawer
    :open="showDrawer"
    :header-height="getContentWrapperHeight"
    :z-index="$options.DRAWER_Z_INDEX"
    @close="$emit('close')"
  >
    <template v-if="framework" #title>
      <div>
        <h2 class="gl-mt-0">
          {{ framework.name }}
          <gl-label
            v-if="defaultFramework"
            :background-color="framework.color"
            :title="s__('ComplianceFrameworksReport|Default')"
            size="sm"
          />
        </h2>
        <gl-button
          class="gl-my-3"
          category="primary"
          variant="confirm"
          @click="$emit('edit', framework)"
        >
          {{ s__('ComplianceFrameworksReport|Edit framework') }}
        </gl-button>
      </div>
    </template>

    <template v-if="framework" #default>
      <div>
        <h4 class="gl-mt-0">
          {{ s__('ComplianceFrameworksReport|Associated Projects') }}
        </h4>
      </div>
    </template>
  </gl-drawer>
</template>
