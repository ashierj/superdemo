<script>
import { GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import EMPTY_CHART_SVG from '@gitlab/svgs/dist/illustrations/chart-empty-state.svg?url';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import { visitUrl, isSafeURL } from '~/lib/utils/url_utility';
import { ingestedAtTimeAgo } from '../utils';
import MetricsChart from './metrics_chart.vue';
import FilteredSearch from './filter_bar/metrics_filtered_search.vue';

export default {
  i18n: {
    error: s__(
      'ObservabilityMetrics|Error: Failed to load metrics details. Try reloading the page.',
    ),
    metricType: s__('ObservabilityMetrics|Type'),
    lastIngested: s__('ObservabilityMetrics|Last ingested'),
    noData: s__('ObservabilityMetrics|No data found for the selected metric.'),
  },
  components: {
    GlLoadingIcon,
    MetricsChart,
    GlEmptyState,
    FilteredSearch,
  },
  props: {
    observabilityClient: {
      required: true,
      type: Object,
    },
    metricId: {
      required: true,
      type: String,
    },
    metricType: {
      required: true,
      type: String,
    },
    metricsIndexUrl: {
      required: true,
      type: String,
      validator: (val) => isSafeURL(val),
    },
  },
  data() {
    return {
      metricData: [],
      dimensions: [],
      loading: false,
      searchMetadata: null,
    };
  },
  computed: {
    header() {
      return {
        title: this.metricId,
        type: this.metricType,
        lastIngested: ingestedAtTimeAgo(this.searchMetadata?.last_ingested_at),
        description: this.searchMetadata?.description,
      };
    },
  },
  created() {
    this.validateAndFetch();
  },
  methods: {
    async validateAndFetch() {
      if (!this.metricId || !this.metricType) {
        createAlert({
          message: this.$options.i18n.error,
        });
        return;
      }
      this.loading = true;
      try {
        const enabled = await this.observabilityClient.isObservabilityEnabled();
        if (enabled) {
          await this.fetchMetricSearchMetadata();
          if (this.searchMetadata) {
            await this.fetchMetricData();
          }
        } else {
          this.goToMetricsIndex();
        }
      } catch (e) {
        createAlert({
          message: this.$options.i18n.error,
        });
      } finally {
        this.loading = false;
      }
    },
    async fetchMetricSearchMetadata() {
      try {
        this.searchMetadata = await this.observabilityClient.fetchMetricSearchMetadata(
          this.metricId,
          this.metricType,
        );
      } catch (e) {
        createAlert({
          message: this.$options.i18n.error,
        });
      }
    },
    async fetchMetricData() {
      this.loading = true;
      try {
        this.metricData = await this.observabilityClient.fetchMetric(
          this.metricId,
          this.metricType,
        );
        // TODO fetch dimensions from API https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/2488
        this.dimensions = ['dimension_one', 'dimension_two'];
      } catch (e) {
        createAlert({
          message: this.$options.i18n.error,
        });
      } finally {
        this.loading = false;
      }
    },
    goToMetricsIndex() {
      visitUrl(this.metricsIndexUrl);
    },
  },
  EMPTY_CHART_SVG,
};
</script>

<template>
  <div v-if="loading" class="gl-py-5">
    <gl-loading-icon size="lg" />
  </div>

  <div v-else data-testid="metric-details" class="gl-m-7">
    <div data-testid="metric-header">
      <h1 class="gl-font-size-h1 gl-my-0" data-testid="metric-title">{{ header.title }}</h1>
      <p class="gl-my-0" data-testid="metric-type">
        <strong>{{ $options.i18n.metricType }}:&nbsp;</strong>{{ header.type }}
      </p>
      <p class="gl-my-0" data-testid="metric-last-ingested">
        <strong>{{ $options.i18n.lastIngested }}:&nbsp;</strong>{{ header.lastIngested }}
      </p>
      <p class="gl-my-0" data-testid="metric-description">{{ header.description }}</p>
    </div>

    <div class="gl-my-6">
      <filtered-search v-if="dimensions.length > 0" :dimensions="dimensions" />
      <metrics-chart v-if="metricData.length > 0" :metric-data="metricData" />
      <gl-empty-state v-else :svg-path="$options.EMPTY_CHART_SVG">
        <template #title>
          <p class="gl-font-lg gl-my-0">{{ $options.i18n.noData }}</p>
          <p class="gl-font-md gl-my-0">
            <strong>{{ $options.i18n.lastIngested }}:&nbsp;</strong>{{ header.lastIngested }}
          </p>
        </template>
      </gl-empty-state>
    </div>
  </div>
</template>
