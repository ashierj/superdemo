<script>
import { GlTable, GlLink, GlLabel } from '@gitlab/ui';
import { s__ } from '~/locale';
import { formatDate } from '~/lib/utils/datetime/date_format_utility';

const severityConfig = [
  { range: [1, 4], title: s__('ObservabilityLogs|Trace'), color: '#808080' },
  { range: [5, 8], title: s__('ObservabilityLogs|Debug'), color: '#808080' },
  { range: [9, 12], title: s__('ObservabilityLogs|Info'), color: '#808080' },
  { range: [13, 16], title: s__('ObservabilityLogs|Warning'), color: '#ed9121' },
  { range: [17, 20], title: s__('ObservabilityLogs|Error'), color: '#dc143c' },
  { range: [21, 24], title: s__('ObservabilityLogs|Fatal'), color: '#c21e56' },
];

const defaultSeverity = severityConfig[1]; // default: Debug

export default {
  i18n: {
    title: s__('ObservabilityLogs|Logs'),
    emptyText: s__('ObservabilityLogs|No logs to display.'),
    emptyLinkText: s__('ObservabilityLogs|Check again'),
  },
  fields: [
    {
      key: 'timestamp',
      label: s__('ObservabilityLogs|Date'),
      tdAttr: { 'data-testid': 'log-timestamp' },
    },
    {
      key: 'severity_number',
      label: s__('ObservabilityLogs|Level'),
      tdAttr: { 'data-testid': 'log-level' },
      thClass: 'gl-w-10p',
    },
    {
      key: 'service_name',
      label: s__('ObservabilityLogs|Service'),
      tdAttr: { 'data-testid': 'log-service' },
      tdClass: 'gl-word-break-word',
    },
    {
      key: 'body',
      label: s__('ObservabilityLogs|Message'),
      tdAttr: { 'data-testid': 'log-message' },
      thClass: 'gl-w-half',
      tdClass: 'gl-text-truncate',
    },
  ],
  components: {
    GlTable,
    GlLink,
    GlLabel,
  },
  props: {
    logs: {
      required: true,
      type: Array,
    },
  },
  computed: {
    formattedLogs() {
      return this.logs.map((log) => ({
        ...log,
        timestamp: formatDate(log.timestamp),
      }));
    },
  },
  methods: {
    severityLabel(severityNumber) {
      const severity = severityConfig.find(
        ({ range }) => severityNumber >= range[0] && severityNumber <= range[1],
      );
      return severity || defaultSeverity;
    },
  },
};
</script>

<template>
  <div>
    <h4 class="gl-display-block gl-md-display-none! gl-my-5">{{ $options.i18n.title }}</h4>

    <gl-table
      :items="logs"
      :fields="$options.fields"
      show-empty
      fixed
      stacked="md"
      :tbody-tr-attr="{ 'data-testid': 'log-row' }"
    >
      <template #cell(severity_number)="{ item }">
        <gl-label
          :background-color="severityLabel(item.severity_number).color"
          :title="severityLabel(item.severity_number).title"
        />
      </template>
      <!-- no date template -->
      <template #empty>
        <div class="gl-text-center">
          {{ $options.i18n.emptyText }}
          <gl-link @click="$emit('reload')">{{ $options.i18n.emptyLinkText }}</gl-link>
        </div>
      </template>
    </gl-table>
  </div>
</template>
