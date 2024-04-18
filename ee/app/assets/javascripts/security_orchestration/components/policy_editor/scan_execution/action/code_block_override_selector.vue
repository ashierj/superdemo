<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import {
  CUSTOM_OVERRIDE_OPTIONS,
  CUSTOM_OVERRIDE_OPTIONS_LISTBOX_ITEMS,
  INJECT,
} from 'ee/security_orchestration/components/policy_editor/scan_execution/constants';
import { validateOverrideValues } from 'ee/security_orchestration/components/policy_editor/scan_execution//lib';

export default {
  CUSTOM_OVERRIDE_OPTIONS_LISTBOX_ITEMS,
  name: 'CodeBlockOverrideSelector',
  components: {
    GlCollapsibleListbox,
  },
  props: {
    overrideType: {
      type: String,
      required: false,
      default: INJECT,
      validator: validateOverrideValues,
    },
  },
  computed: {
    toggleText() {
      return CUSTOM_OVERRIDE_OPTIONS[this.overrideType];
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    label-for="file-path"
    :items="$options.CUSTOM_OVERRIDE_OPTIONS_LISTBOX_ITEMS"
    :toggle-text="toggleText"
    :selected="overrideType"
    @select="$emit('select', $event)"
  />
</template>
