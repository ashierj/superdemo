<script>
import { GlDropdownText, GlFilteredSearchToken } from '@gitlab/ui';
import { s__ } from '~/locale';
import { SERVICE_NAME_FILTER_TOKEN_TYPE, OPERATION_FILTER_TOKEN_TYPE } from './filters';

export default {
  components: {
    GlFilteredSearchToken,
    GlDropdownText,
  },
  i18n: {
    disabledText: s__('Tracing|You must select a Service and Operation first.'),
  },
  props: {
    active: {
      type: Boolean,
      required: true,
    },
    config: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
    currentValue: {
      type: Array,
      required: true,
    },
  },
  computed: {
    isEnabled() {
      const requiredFilters = [SERVICE_NAME_FILTER_TOKEN_TYPE, OPERATION_FILTER_TOKEN_TYPE];
      return requiredFilters.every((filter) =>
        this.currentValue.find(({ type }) => type === filter),
      );
    },
  },
};
</script>

<template>
  <gl-filtered-search-token
    v-bind="{ ...$props, ...$attrs }"
    :config="config"
    :value="value"
    :active="active"
    :view-only="!isEnabled"
    v-on="$listeners"
  >
    <template #suggestions>
      <gl-dropdown-text v-if="!isEnabled">{{ $options.i18n.disabledText }}</gl-dropdown-text>
    </template>
  </gl-filtered-search-token>
</template>
