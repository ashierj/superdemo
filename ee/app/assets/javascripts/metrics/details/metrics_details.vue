<script>
import { GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import EMPTY_CHART_SVG from '@gitlab/svgs/dist/illustrations/chart-empty-state.svg?url';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import { visitUrl, isSafeURL } from '~/lib/utils/url_utility';
import {
  prepareTokens,
  processFilters as processFilteredSearchFilters,
} from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import { periodToDate } from '~/observability/utils';
import axios from '~/lib/utils/axios_utils';
import { ingestedAtTimeAgo } from '../utils';
import MetricsChart from './metrics_chart.vue';
import FilteredSearch from './filter_bar/metrics_filtered_search.vue';

const DEFAULT_TIME_RANGE = '1h';

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
    const defaultRange = periodToDate(DEFAULT_TIME_RANGE);
    return {
      metricData: [],
      searchMetadata: null,
      // TODO get filters from query params https://gitlab.com/gitlab-org/opstrace/opstrace/-/work_items/2605
      filters: {
        attributes: [],
        dateRange: {
          value: DEFAULT_TIME_RANGE,
          startDarte: defaultRange.min,
          endDate: defaultRange.max,
        },
      },
      apiAbortController: null,
      loading: false,
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
    attributeFiltersValue() {
      // only attributes are used by the filtered_search component, so only those needs processing
      return prepareTokens(this.filters.attributes);
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
          await Promise.all([this.fetchMetricSearchMetadata(), await this.fetchMetricData()]);
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
        this.apiAbortController = new AbortController();
        this.metricData = await this.observabilityClient.fetchMetric(
          this.metricId,
          this.metricType,
          { filters: this.filters, abortController: this.apiAbortController },
        );
      } catch (e) {
        if (!axios.isCancel(e)) {
          createAlert({
            message: this.$options.i18n.error,
          });
        }
      } finally {
        this.apiAbortController = null;
        this.loading = false;
      }
    },
    goToMetricsIndex() {
      visitUrl(this.metricsIndexUrl);
    },
    onFilter({ attributes, dateRange, groupBy }) {
      this.filters = {
        // only attributes are used by the filtered_search component, so only those needs processing
        attributes: processFilteredSearchFilters(attributes),
        dateRange,
        groupBy,
      };
      this.fetchMetricData();
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
      <filtered-search
        v-if="searchMetadata"
        :search-metadata="searchMetadata"
        :attribute-filters="attributeFiltersValue"
        :date-range-filter="filters.dateRange"
        :group-by-filter="filters.groupBy"
        @filter="onFilter"
      />
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
