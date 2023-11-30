<script>
import { GlLineChart, GlChartSeriesLabel } from '@gitlab/ui/dist/charts';
import { s__ } from '~/locale';
import { formatDate } from '~/lib/utils/datetime_utility';

export default {
  components: {
    GlLineChart,
    GlChartSeriesLabel,
  },
  i18n: {
    xAxisTitle: s__('ObservabilityMetrics|Date'),
    yAxisTitle: s__('ObservabilityMetrics|Value'),
  },
  props: {
    metricData: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      tooltipTitle: '',
      tooltipContent: [],
    };
  },
  computed: {
    chartData() {
      return this.metricData.map((metric) => {
        // note date timestamps are in nano, so converting them to ms here
        const data = metric.values.map((value) => [
          value[0] / 1e6,
          value[1],
          { ...metric.attributes },
        ]);
        return {
          name: Object.entries(metric.attributes)
            .map(([k, v]) => `${k}: ${v}`)
            .join(', '),
          data,
        };
      });
    },
    chartOption() {
      const yUnit = this.metricData?.[0]?.unit;
      const yAxisTitle = this.$options.i18n.yAxisTitle + (yUnit ? ` (${yUnit})` : '');
      return {
        dataZoom: [
          {
            type: 'slider',
          },
        ],
        xAxis: {
          type: 'time',
          name: this.$options.i18n.xAxisTitle,
        },
        yAxis: {
          name: yAxisTitle,
        },
      };
    },
  },
  methods: {
    formatTooltipText({ seriesData }) {
      // reset the tooltip
      this.tooltipTitle = '';
      this.tooltipContent = [];

      if (!Array.isArray(seriesData) || seriesData.length === 0) return;

      if (Array.isArray(seriesData[0].data)) {
        const [dateTime] = seriesData[0].data;
        this.tooltipTitle = formatDate(dateTime, 'mmm d, yyyy H:MM:ss');
      }

      this.tooltipContent = seriesData.map(({ seriesName, color, seriesId, data }) => {
        const [, metric, attr] = data;
        return {
          seriesId,
          label: seriesName,
          attributes: Object.entries(attr).map(([k, v]) => ({ key: k, value: v })),
          value: parseFloat(metric).toFixed(3),
          color,
        };
      });
    },
  },
};
</script>

<template>
  <gl-line-chart
    class="gl-mb-7"
    :option="chartOption"
    :data="chartData"
    responsive
    :format-tooltip-text="formatTooltipText"
  >
    <template #tooltip-title>
      <div data-testid="metric-tooltip-title">{{ tooltipTitle }}</div>
    </template>

    <template #tooltip-content>
      <div
        v-for="metric in tooltipContent"
        :key="metric.seriesId"
        data-testid="metric-tooltip-content"
        class="gl-display-flex gl-justify-content-space-between gl-font-sm gl-mb-1"
      >
        <gl-chart-series-label :color="metric.color" class="gl-line-height-normal gl-mr-7">
          <div v-for="attr in metric.attributes" :key="attr.key + attr.value">
            <span class="gl-font-weight-bold">{{ attr.key }}: </span>{{ attr.value }}
          </div>
        </gl-chart-series-label>

        <div data-testid="metric-tooltip-value" class="gl-font-weight-bold">
          {{ metric.value }}
        </div>
      </div>
    </template>
  </gl-line-chart>
</template>
