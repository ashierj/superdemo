<script>
import Vue from 'vue';
import { GlLoadingIcon, GlTable, GlToast } from '@gitlab/ui';
import { __, s__ } from '~/locale';

Vue.use(GlToast);

export default {
  name: 'FrameworksTable',
  components: {
    GlLoadingIcon,
    GlTable,
  },
  props: {
    frameworks: {
      type: Array,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
  },
  fields: [
    {
      key: 'frameworkName',
      label: __('Frameworks'),
      thClass: 'gl-vertical-align-middle!',
      tdClass: 'gl-vertical-align-middle!',
      sortable: true,
    },
  ],
  i18n: {
    noFrameworksFound: s__('ComplianceReport|No frameworks found'),
  },
};
</script>
<template>
  <gl-table
    :fields="$options.fields"
    :busy="isLoading"
    :items="frameworks"
    no-local-sorting
    show-empty
    stacked="lg"
    hover
  >
    <template #cell(frameworkName)="{ item }">
      {{ item.name }}
    </template>
    <template #table-busy>
      <gl-loading-icon size="lg" color="dark" class="gl-my-5" />
    </template>
    <template #empty>
      <div class="gl-my-5 gl-text-center" data-testid="frameworks-table-empty-state">
        {{ $options.i18n.noFrameworksFound }}
      </div>
    </template>
  </gl-table>
</template>
