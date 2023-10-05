<script>
import { GlTab, GlTabs } from '@gitlab/ui';
import { __ } from '~/locale';
import CiResourceReadme from './ci_resource_readme.vue';

export default {
  components: {
    CiResourceReadme,
    GlTab,
    GlTabs,
  },
  props: {
    resourceId: {
      type: String,
      required: true,
    },
  },
  i18n: {
    tabs: {
      readme: __('Readme'),
    },
  },
};
</script>

<template>
  <gl-tabs>
    <gl-tab :title="$options.i18n.tabs.readme" lazy>
      <ci-resource-readme :resource-id="resourceId" />
    </gl-tab>
  </gl-tabs>
</template>
<style></style>
