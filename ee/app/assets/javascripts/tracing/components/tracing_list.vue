<script>
import { GlLoadingIcon, GlInfiniteScroll } from '@gitlab/ui';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import { visitUrl, joinPaths } from '~/lib/utils/url_utility';
import UrlSync from '~/vue_shared/components/url_sync.vue';
import { contentTop } from '~/lib/utils/common_utils';
import {
  queryToFilterObj,
  filterObjToQuery,
  filterObjToFilterToken,
  filterTokensToFilterObj,
} from '../filters';
import TracingEmptyState from './tracing_empty_state.vue';
import TracingTableList from './tracing_table_list.vue';
import FilteredSearch from './tracing_list_filtered_search.vue';
import ScatterChart from './tracing_scatter_chart.vue';
import { periodFilterToDate } from './trace_utils';

const PAGE_SIZE = 500;
const CHART_HEIGHT = 300;
const TRACING_LIST_VERTICAL_PADDING = 120; // Accounts for the search bar height + the legend height + some more v padding

export default {
  components: {
    GlLoadingIcon,
    TracingTableList,
    TracingEmptyState,
    FilteredSearch,
    UrlSync,
    GlInfiniteScroll,
    ScatterChart,
  },
  props: {
    observabilityClient: {
      required: true,
      type: Object,
    },
  },
  data() {
    return {
      loading: true,
      /**
       * tracingEnabled: boolean | null.
       * null identifies a state where we don't know if tracing is enabled or not (e.g. when fetching the status from the API fails)
       */
      tracingEnabled: null,
      traces: [],
      filters: queryToFilterObj(window.location.search),
      nextPageToken: null,
      chartRangeMin: null,
      chartRangeMax: null,
    };
  },
  computed: {
    query() {
      return filterObjToQuery(this.filters);
    },
    initialFilterValue() {
      return filterObjToFilterToken(this.filters);
    },
    infiniteScrollLegend() {
      if (this.traces.length > 0) return s__(`Tracing|Showing ${this.traces.length} traces`);
      return null;
    },
    listHeight() {
      return window.innerHeight - contentTop() - TRACING_LIST_VERTICAL_PADDING - CHART_HEIGHT;
    },
  },
  created() {
    this.checkEnabled();
  },
  methods: {
    async checkEnabled() {
      this.loading = true;
      try {
        this.tracingEnabled = await this.observabilityClient.isTracingEnabled();
        if (this.tracingEnabled) {
          await this.fetchTraces();
        }
      } catch (e) {
        createAlert({
          message: s__('Tracing|Failed to load page.'),
        });
      } finally {
        this.loading = false;
      }
    },
    async enableTracing() {
      this.loading = true;
      try {
        await this.observabilityClient.enableTraces();
        this.tracingEnabled = true;
        await this.fetchTraces();
      } catch (e) {
        createAlert({
          message: s__('Tracing|Failed to enable tracing.'),
        });
      } finally {
        this.loading = false;
      }
    },
    async fetchTraces({ skipUpdatingChartRange = false } = {}) {
      this.loading = true;

      try {
        const {
          traces,
          next_page_token: nextPageToken,
        } = await this.observabilityClient.fetchTraces({
          filters: this.filters,
          pageToken: this.nextPageToken,
          pageSize: PAGE_SIZE,
        });
        if (!skipUpdatingChartRange) {
          const { min, max } = periodFilterToDate(this.filters);
          this.chartRangeMax = max;
          this.chartRangeMin = min;
        }

        this.traces = [...this.traces, ...traces];
        if (nextPageToken) {
          this.nextPageToken = nextPageToken;
        }
      } catch (e) {
        createAlert({
          message: s__('Tracing|Failed to load traces.'),
        });
      } finally {
        this.loading = false;
      }
    },
    selectTrace({ traceId }) {
      visitUrl(joinPaths(window.location.pathname, traceId));
    },
    handleFilters(filterTokens) {
      this.filters = filterTokensToFilterObj(filterTokens);
      this.nextPageToken = null;
      this.traces = [];
      this.fetchTraces();
    },
    bottomReached() {
      this.fetchTraces({ skipUpdatingChartRange: true });
    },
    chartItemSelected({ traceId }) {
      this.selectTrace({ traceId });
    },
  },
  CHART_HEIGHT,
};
</script>

<template>
  <div>
    <div v-if="loading && traces.length === 0" class="gl-py-5">
      <gl-loading-icon size="lg" />
    </div>

    <template v-else-if="tracingEnabled !== null">
      <tracing-empty-state v-if="tracingEnabled === false" @enable-tracing="enableTracing" />

      <template v-else>
        <url-sync :query="query" />
        <filtered-search
          :initial-filters="initialFilterValue"
          :observability-client="observabilityClient"
          @submit="handleFilters"
        />
        <scatter-chart
          :height="$options.CHART_HEIGHT"
          :range-min="chartRangeMin"
          :range-max="chartRangeMax"
          :traces="traces"
          @chart-item-selected="chartItemSelected"
          @reload-data="fetchTraces"
        />

        <gl-infinite-scroll
          :max-list-height="listHeight"
          :fetched-items="traces.length"
          @bottomReached="bottomReached"
        >
          <template #items>
            <tracing-table-list
              :traces="traces"
              @reload="fetchTraces"
              @trace-selected="selectTrace"
            />
          </template>

          <template #default>
            <gl-loading-icon v-if="loading" size="md" />
            <span v-else data-testid="tracing-infinite-scrolling-legend">{{
              infiniteScrollLegend
            }}</span>
          </template>
        </gl-infinite-scroll>
      </template>
    </template>
  </div>
</template>
