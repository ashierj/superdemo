<script>
import { GlTable, GlTruncate, GlBadge } from '@gitlab/ui';
import { s__, __, sprintf, n__ } from '~/locale';
import { formatDate } from '~/lib/utils/datetime/date_format_utility';
import { formatTraceDuration } from '../trace_utils';

export default {
  name: 'TracingTable',
  i18n: {
    title: s__('Tracing|Traces'),
    emptyText: __('No results found'),
  },
  fields: [
    {
      key: 'timestamp',
      label: s__('Tracing|Date'),
      tdAttr: { 'data-testid': 'trace-timestamp' },
    },
    {
      key: 'service_name',
      label: s__('Tracing|Service'),
      tdAttr: { 'data-testid': 'trace-service' },
    },
    {
      key: 'operation',
      label: s__('Tracing|Operation'),
      tdAttr: { 'data-testid': 'trace-operation' },
    },
    {
      key: 'duration',
      label: s__('Tracing|Duration'),
      thClass: 'gl-w-15p',
      tdAttr: { 'data-testid': 'trace-duration' },
    },
  ],
  components: {
    GlTable,
    GlTruncate,
    GlBadge,
  },
  props: {
    traces: {
      required: true,
      type: Array,
    },
    highlightedTraceId: {
      required: false,
      type: String,
      default: null,
    },
  },
  computed: {
    formattedTraces() {
      return this.traces.map((x) => ({
        ...x,
        timestamp: formatDate(x.timestamp),
        duration: formatTraceDuration(x.duration_nano),
      }));
    },
  },
  methods: {
    onRowClicked(item, _index, event) {
      this.$emit('trace-clicked', { traceId: item.trace_id, clickEvent: event });
    },
    rowClass(item, type) {
      if (!item || type !== 'row') return '';
      if (item.trace_id === this.highlightedTraceId) return 'gl-bg-t-gray-a-08';
      return '';
    },
    matchesBadgeContent(item) {
      const spans = n__('Tracing|%{count} span', 'Tracing|%{count} spans', item.total_spans);
      const matches = n__(
        'Tracing|%{count} match',
        'Tracing|%{count} matches',
        item.matched_span_count,
      );
      return `${sprintf(spans, { count: item.total_spans })} / ${sprintf(matches, {
        count: item.matched_span_count,
      })}`;
    },
  },
};
</script>

<template>
  <div>
    <h4 class="gl-display-block gl-md-display-none! gl-my-5">{{ $options.i18n.title }}</h4>

    <gl-table
      :items="formattedTraces"
      :fields="$options.fields"
      show-empty
      fixed
      stacked="md"
      :tbody-tr-class="rowClass"
      selectable
      select-mode="single"
      selected-variant=""
      :tbody-tr-attr="{ 'data-testid': 'trace-row' }"
      @row-clicked="onRowClicked"
    >
      <template #cell(timestamp)="{ item }">
        {{ item.timestamp }}
        <div class="gl-mt-4">
          <gl-badge variant="info">{{ matchesBadgeContent(item) }}</gl-badge>
        </div>
      </template>

      <template #cell(service_name)="{ item }">
        <gl-truncate :text="item.service_name" with-tooltip />
      </template>

      <template #cell(operation)="{ item }">
        <gl-truncate :text="item.operation" with-tooltip />
      </template>

      <template #empty>
        <div class="gl-text-center">
          <span>{{ $options.i18n.emptyText }}</span>
        </div>
      </template>
    </gl-table>
  </div>
</template>
