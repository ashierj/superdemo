<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { s__ } from '~/locale';
import {
  CUSTOM_ACTION_OPTIONS,
  CUSTOM_ACTION_OPTIONS_LISTBOX_ITEMS,
} from 'ee/security_orchestration/components/policy_editor/scan_execution/constants';

export default {
  CUSTOM_ACTION_OPTIONS_LISTBOX_ITEMS,
  i18n: {
    customSectionTypeLabel: s__('ScanExecutionPolicy|Choose a method to execute code'),
  },
  name: 'CodeBlockSourceSelector',
  components: {
    GlCollapsibleListbox,
  },
  props: {
    selectedType: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    toggleText() {
      return CUSTOM_ACTION_OPTIONS[this.selectedType] || this.$options.i18n.customSectionTypeLabel;
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    label-for="file-path"
    :items="$options.CUSTOM_ACTION_OPTIONS_LISTBOX_ITEMS"
    :toggle-text="toggleText"
    :selected="selectedType"
    @select="$emit('select', $event)"
  />
</template>
