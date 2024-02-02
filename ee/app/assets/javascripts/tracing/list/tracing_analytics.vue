<script>
import { GlLineChart, GlColumnChart } from '@gitlab/ui/dist/charts';
import { throttle } from 'lodash';
import { s__ } from '~/locale';
import { contentTop } from '~/lib/utils/common_utils';
import { durationNanoToMs } from '../trace_utils';

const intervalToTimestamp = (interval) => new Date(interval * 1000);
const toFixed = (n) => parseFloat(n).toFixed(2);

const buildVolumeRateData = ({ interval, trace_rate: traceRate = 0 }, volumeData) => {
  volumeData.push([intervalToTimestamp(interval), toFixed(traceRate)]);
};

const buildErrorRateData = ({ interval, error_rate: errorRate = 0 }, errorData) => {
  errorData.push([intervalToTimestamp(interval), toFixed(Math.min(errorRate * 100, 100))]);
};

const buildDurationData = (
  {
    interval,
    p90_duration_nano: p90 = 0,
    p95_duration_nano: p95 = 0,
    p75_duration_nano: p75 = 0,
    p50_duration_nano: p50 = 0,
  },
  durationData,
) => {
  const timestamp = intervalToTimestamp(interval);
  durationData.p90.push([timestamp, toFixed(durationNanoToMs(p90))]);
  durationData.p95.push([timestamp, toFixed(durationNanoToMs(p95))]);
  durationData.p75.push([timestamp, toFixed(durationNanoToMs(p75))]);
  durationData.p50.push([timestamp, toFixed(durationNanoToMs(p50))]);
};

export default {
  components: {
    GlLineChart,
    GlColumnChart,
  },
  i18n: {
    durationLabel: s__('Tracing|Duration (ms)'),
    errorRateLabel: s__('Tracing|Error rate (%%)'),
    volumeLabel: s__('Tracing|Request rate (req/s)'),
  },
  props: {
    analytics: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      chartHeight: 0,
    };
  },
  computed: {
    seriesData() {
      const errorRateData = [];
      const volumeRateData = [];
      const durationData = { p90: [], p95: [], p75: [], p50: [] };

      this.analytics.forEach((metric) => {
        buildVolumeRateData(metric, volumeRateData);
        buildErrorRateData(metric, errorRateData);
        buildDurationData(metric, durationData);
      });
      return {
        errorRateData,
        durationData,
        volumeRateData,
      };
    },
    errorRateChartData() {
      return [
        {
          type: 'line',
          name: this.$options.i18n.errorRateLabel,
          data: this.seriesData.errorRateData,
          lineStyle: {
            color: '#F15642',
          },
          itemStyle: {
            color: '#F15642',
          },
        },
      ];
    },
    volumeRateChartData() {
      return [
        {
          data: this.seriesData.volumeRateData,
          name: this.$options.i18n.volumeLabel,
        },
      ];
    },
    durationChartData() {
      return [
        {
          name: 'p90',
          data: this.seriesData.durationData.p90,
          lineStyle: { color: '#e99b60' },
          itemStyle: { color: '#e99b60' },
        },
        {
          name: 'p95',
          data: this.seriesData.durationData.p95,
          lineStyle: { color: '#81ac41' },
          itemStyle: { color: '#81ac41' },
        },
        {
          name: 'p75',
          data: this.seriesData.durationData.p75,
          lineStyle: { color: '#3F8EAD' },
          itemStyle: { color: '#3F8EAD' },
        },
        {
          name: 'p50',
          data: this.seriesData.durationData.p50,
          lineStyle: { color: '#617ae2' },
          itemStyle: { color: '#617ae2' },
        },
      ];
    },
    durationChartOption() {
      return {
        xAxis: {
          type: 'time',
          name: this.$options.i18n.durationLabel,
        },
        yAxis: {
          name: '',
        },
      };
    },
    volumeChartOption() {
      return {
        xAxis: {
          type: 'time',
          name: this.$options.i18n.volumeLabel,
        },
        yAxis: {
          name: '',
          axisLabel: {
            formatter: '{value}',
          },
        },
      };
    },
    errorChartOption() {
      return {
        xAxis: {
          type: 'time',
          name: this.$options.i18n.errorRateLabel,
        },
        yAxis: {
          name: '',
          axisLabel: {
            formatter: '{value}',
          },
        },
      };
    },
  },
  created() {
    this.resizeChart();

    this.resizeThrottled = throttle(() => {
      this.resizeChart();
    }, 400);
    window.addEventListener('resize', this.resizeThrottled);
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.resizeThrottled, false);
  },
  methods: {
    resizeChart() {
      const containerHeight = window.innerHeight - contentTop();
      this.chartHeight = Math.max(100, (containerHeight * 20) / 100);
    },
  },
};
</script>

<template>
  <div v-if="analytics.length" class="gl-display-flex gl-flex-direction-row gl-mb-8">
    <div class="analytics-chart">
      <gl-column-chart
        :bars="volumeRateChartData"
        :height="chartHeight"
        :option="volumeChartOption"
        responsive
        :x-axis-title="$options.i18n.volumeLabel"
        x-axis-type="time"
        y-axis-title=""
      />
    </div>
    <div class="analytics-chart">
      <gl-line-chart
        :data="errorRateChartData"
        :height="chartHeight"
        :include-legend-avg-max="false"
        :option="errorChartOption"
        :show-legend="false"
        responsive
      />
    </div>
    <div class="analytics-chart">
      <gl-line-chart
        :data="durationChartData"
        :height="chartHeight"
        :include-legend-avg-max="false"
        :option="durationChartOption"
        responsive
      />
    </div>
  </div>
</template>

<style>
.analytics-chart {
  flex: 1;
}
</style>
