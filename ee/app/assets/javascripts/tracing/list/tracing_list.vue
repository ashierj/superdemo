<script>
import { GlLoadingIcon, GlInfiniteScroll } from '@gitlab/ui';
import { throttle } from 'lodash';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import { visitUrl, joinPaths, queryToObject } from '~/lib/utils/url_utility';
import UrlSync from '~/vue_shared/components/url_sync.vue';
import { contentTop, isMetaClick } from '~/lib/utils/common_utils';
import { DEFAULT_SORTING_OPTION } from '~/observability/constants';
import {
  queryToFilterObj,
  filterObjToQuery,
  filterObjToFilterToken,
  filterTokensToFilterObj,
} from './filter_bar/filters';
import TracingTableList from './tracing_table.vue';
import FilteredSearch from './filter_bar/tracing_filtered_search.vue';
import TracingAnalytics from './tracing_analytics.vue';

const PAGE_SIZE = 50;
const TRACING_LIST_VERTICAL_PADDING = 140; // Accounts for the search bar height + the legend height + some more v padding

export default {
  components: {
    GlLoadingIcon,
    TracingTableList,
    FilteredSearch,
    UrlSync,
    GlInfiniteScroll,
    TracingAnalytics,
  },
  props: {
    observabilityClient: {
      required: true,
      type: Object,
    },
  },
  data() {
    const query = window.location.search;
    const { sortBy, ...filterQuery } = queryToObject(query, { gatherArrays: true });

    return {
      loadingTraces: false,
      loadingAnalytics: false,
      traces: [],
      analytics: [],
      filters: queryToFilterObj(filterQuery),
      nextPageToken: null,
      sortBy: sortBy || DEFAULT_SORTING_OPTION,
      listHeight: 0,
      analyticsChartsHeight: 0,
    };
  },
  computed: {
    query() {
      const filterQuery = filterObjToQuery(this.filters);
      return {
        ...filterQuery,
        sortBy: this.sortBy,
      };
    },
    initialFilterValue() {
      return filterObjToFilterToken(this.filters);
    },
    infiniteScrollLegend() {
      if (this.traces.length > 0) return s__(`Tracing|Showing ${this.traces.length} traces`);
      return null;
    },
  },
  created() {
    this.fetchTraces();
    this.fetchAnalytics();
  },
  mounted() {
    this.resize();
    this.resizeThrottled = throttle(() => {
      this.resize();
    }, 400);
    window.addEventListener('resize', this.resizeThrottled);
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.resizeThrottled, false);
  },
  methods: {
    async fetchTraces() {
      this.loadingTraces = true;
      try {
        const {
          traces,
          next_page_token: nextPageToken,
        } = await this.observabilityClient.fetchTraces({
          filters: this.filters,
          pageToken: this.nextPageToken,
          pageSize: PAGE_SIZE,
          sortBy: this.sortBy,
        });
        this.traces = [...this.traces, ...traces];
        if (nextPageToken) {
          this.nextPageToken = nextPageToken;
        }
      } catch (e) {
        createAlert({
          message: s__('Tracing|Failed to load traces.'),
        });
      } finally {
        this.loadingTraces = false;
      }
    },
    async fetchAnalytics() {
      this.loadingAnalytics = true;
      try {
        this.analytics = await this.observabilityClient.fetchTracesAnalytics({
          filters: this.filters,
        });
      } catch {
        createAlert({
          message: s__('Tracing|Failed to load tracing analytics.'),
        });
      } finally {
        this.loadingAnalytics = false;
      }
    },
    onTraceClicked({ traceId, clickEvent = {} }) {
      const external = isMetaClick(clickEvent);
      visitUrl(joinPaths(window.location.pathname, traceId), external);
    },
    handleFilters(filterTokens) {
      this.filters = filterTokensToFilterObj(filterTokens);
      this.nextPageToken = null;
      this.traces = [];
      this.analytics = [];
      this.fetchTraces();
      this.fetchAnalytics();
    },
    onSort(sortBy) {
      this.sortBy = sortBy;
      this.nextPageToken = null;
      this.traces = [];
      this.fetchTraces();
    },
    bottomReached() {
      this.fetchTraces();
    },
    resize() {
      const containerHeight = window.innerHeight - contentTop();
      this.analyticsChartsHeight = Math.max(100, (containerHeight * 20) / 100);
      this.listHeight =
        containerHeight - this.analyticsChartsHeight - TRACING_LIST_VERTICAL_PADDING;
    },
  },
};
</script>

<template>
  <div class="gl-px-8">
    <div v-if="loadingTraces && traces.length === 0" class="gl-py-5">
      <gl-loading-icon size="lg" />
    </div>

    <template v-else>
      <url-sync :query="query" />
      <filtered-search
        :initial-filters="initialFilterValue"
        :observability-client="observabilityClient"
        :initial-sort="sortBy"
        @submit="handleFilters"
        @sort="onSort"
      />

      <tracing-analytics
        v-if="traces.length"
        :analytics="analytics"
        :loading="loadingAnalytics"
        :chart-height="analyticsChartsHeight"
      />

      <gl-infinite-scroll
        ref="infiniteScroll"
        :max-list-height="listHeight"
        :fetched-items="traces.length"
        @bottomReached="bottomReached"
      >
        <template #items>
          <tracing-table-list ref="tableList" :traces="traces" @trace-clicked="onTraceClicked" />
        </template>

        <template #default>
          <gl-loading-icon v-if="loadingTraces" size="md" />
          <span v-else data-testid="tracing-infinite-scrolling-legend">{{
            infiniteScrollLegend
          }}</span>
        </template>
      </gl-infinite-scroll>
    </template>
  </div>
</template>
