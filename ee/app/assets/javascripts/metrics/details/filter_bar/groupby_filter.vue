<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlCollapsibleListbox,
  },
  i18n: {
    groupByPlaceholderMultipleSelect: s__('ObservabilityMetrics|multiple'),
  },
  props: {
    searchConfig: {
      type: Object,
      required: true,
    },
    selectedDimensions: {
      type: Array,
      required: true,
    },
    selectedFunction: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      groupByDimensions: this.selectedDimensions,
      groupByFunction: this.selectedFunction,
    };
  },
  computed: {
    availableGroupByFunctions() {
      return this.searchConfig.groupByFunctions.map((func) => ({ value: func, text: func }));
    },
    availableGroupByDimensions() {
      return this.searchConfig.dimensions.map((d) => ({ value: d, text: d }));
    },
    groupByLabel() {
      return this.groupByDimensions.length > 1 ? this.groupByDimensions.join(', ') : '';
    },
    groupByToggleText() {
      if (this.groupByDimensions.length > 0) {
        if (this.groupByDimensions.length === 1) {
          return this.groupByDimensions[0];
        }
        return this.$options.i18n.groupByPlaceholderMultipleSelect;
      }
      return '';
    },
  },
  methods: {
    onSelect() {
      this.$emit('groupBy', {
        dimensions: this.groupByDimensions,
        func: this.groupByFunction,
      });
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-flex-direction-row gl-align-items-center gl-gap-3">
    <gl-collapsible-listbox
      v-model="groupByFunction"
      data-testid="group-by-function-dropdown"
      :items="availableGroupByFunctions"
      @select="onSelect"
    />
    <span>{{ __('by') }}</span>
    <gl-collapsible-listbox
      v-model="groupByDimensions"
      data-testid="group-by-dimensions-dropdown"
      :toggle-text="groupByToggleText"
      multiple
      :items="availableGroupByDimensions"
      @select="onSelect"
    />
    <span data-testid="group-by-label">{{ groupByLabel }}</span>
  </div>
</template>
