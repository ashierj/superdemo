<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { s__ } from '~/locale';
import { ANY_MERGE_REQUEST, SCAN_FINDING, LICENSE_FINDING } from '../lib';

export default {
  scanTypeOptions: [
    {
      value: ANY_MERGE_REQUEST,
      text: s__('SecurityOrchestration|Any merge request'),
    },
    {
      value: SCAN_FINDING,
      text: s__('SecurityOrchestration|Security Scan'),
    },
    {
      value: LICENSE_FINDING,
      text: s__('SecurityOrchestration|License Scan'),
    },
  ],
  i18n: {
    scanRuleTypeToggleText: s__('SecurityOrchestration|Select scan type'),
  },
  name: 'ScanTypeSelect',
  components: {
    GlCollapsibleListbox,
  },
  props: {
    scanType: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    scanRuleTypeToggleText() {
      return this.scanType ? '' : this.$options.i18n.scanRuleTypeToggleText;
    },
  },
  methods: {
    setScanType(value) {
      this.$emit('select', value);
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    id="scanType"
    class="gl-display-inline! gl-w-auto gl-align-middle"
    :items="$options.scanTypeOptions"
    :selected="scanType"
    :toggle-text="scanRuleTypeToggleText"
    @select="setScanType"
  />
</template>
