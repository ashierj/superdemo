<script>
import { GlTable, GlLabel } from '@gitlab/ui';
import { s__, __ } from '~/locale';

export default {
  i18n: {
    title: s__('Metrics|Metrics'),
    emptyText: __('No results found'),
  },
  fields: [
    {
      key: 'name',
      label: s__('Metrics|Name'),
      tdAttr: { 'data-testid': 'metric-name' },
    },
    {
      key: 'description',
      label: s__('Metrics|Description'),
      tdAttr: { 'data-testid': 'metric-description' },
    },
    {
      key: 'type',
      label: s__('Metrics|Type'),
      tdAttr: { 'data-testid': 'metric-type' },
    },
  ],
  components: {
    GlTable,
    GlLabel,
  },
  props: {
    metrics: {
      required: true,
      type: Array,
    },
  },
  methods: {
    labelColor(type) {
      // Colors are taken from the label's colors map: gitlab/app/helpers/labels_helper.rb
      switch (type.toLowerCase()) {
        case 'sum':
          return '#6699cc'; // blue-gray
        case 'gauge':
          return '#cd5b45'; // dark-coral
        case 'histogram':
          return '#009966'; // green-cyan
        case 'exponentialhistogram':
          return '#ed9121'; // carrot-orange
        default:
          return '#808080'; // gray
      }
    },
    onRowClicked(item, _index, event) {
      this.$emit('metric-clicked', { metricId: item.name, clickEvent: event });
    },
  },
};
</script>

<template>
  <div>
    <h4 class="gl-display-block gl-md-display-none! gl-my-5">{{ $options.i18n.title }}</h4>

    <gl-table
      :items="metrics"
      :fields="$options.fields"
      show-empty
      fixed
      stacked="md"
      :tbody-tr-attr="{ 'data-testid': 'metric-row' }"
      selectable
      select-mode="single"
      selected-variant=""
      @row-clicked="onRowClicked"
    >
      <template #cell(type)="{ item }">
        <gl-label :background-color="labelColor(item.type)" :title="item.type" />
      </template>
      <!-- no date template -->
      <template #empty>
        <div class="gl-text-center">
          {{ $options.i18n.emptyText }}
        </div>
      </template>
    </gl-table>
  </div>
</template>
