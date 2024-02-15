<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlCollapsibleListbox,
  },
  i18n: {
    groupByPlaceholderMultipleSelect: s__('ObservabilityMetrics|multiple'),
    groupByPlaceholderAllSelect: s__('ObservabilityMetrics|all'),
    groupByPlaceholder: s__('ObservabilityMetrics|Select attributes'),
  },
  props: {
    supportedFunctions: {
      type: Array,
      required: true,
    },
    supportedAttributes: {
      type: Array,
      required: true,
    },
    selectedAttributes: {
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
      groupByAttributes: this.selectedAttributes,
      groupByFunction: this.selectedFunction,
    };
  },
  computed: {
    availableGroupByFunctions() {
      return this.supportedFunctions.map((func) => ({ value: func, text: func }));
    },
    availableGroupByAttributes() {
      return this.supportedAttributes.map((d) => ({ value: d, text: d }));
    },
    groupByLabel() {
      return this.groupByAttributes.length > 1 ? this.groupByAttributes.join(', ') : '';
    },
    groupByToggleText() {
      if (this.groupByAttributes.length > 0) {
        if (this.groupByAttributes.length === 1) {
          return this.groupByAttributes[0];
        }
        if (this.groupByAttributes.length === this.supportedAttributes.length) {
          return this.$options.i18n.groupByPlaceholderAllSelect;
        }
        return this.$options.i18n.groupByPlaceholderMultipleSelect;
      }
      return this.$options.i18n.groupByPlaceholder;
    },
  },
  methods: {
    onSelect() {
      this.$emit('groupBy', {
        attributes: this.groupByAttributes,
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
      v-model="groupByAttributes"
      data-testid="group-by-attributes-dropdown"
      :toggle-text="groupByToggleText"
      multiple
      :items="availableGroupByAttributes"
      @select="onSelect"
    />
    <span data-testid="group-by-label">{{ groupByLabel }}</span>
  </div>
</template>
