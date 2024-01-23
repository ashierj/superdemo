<script>
import { GlFilteredSearchToken } from '@gitlab/ui';
import { s__ } from '~/locale';
import { OPERATORS_IS_NOT } from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearch from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import { OPERATORS_LIKE_NOT } from '~/observability/constants';
import { periodToDate } from '~/observability/utils';
import DateRangeFilter from './date_range_filter.vue';
import GroupByFilter from './groupby_filter.vue';

const DEFAULT_TIME_RANGE = '1h';

export default {
  components: {
    FilteredSearch,
    DateRangeFilter,
    GroupByFilter,
  },
  i18n: {
    searchInputPlaceholder: s__('ObservabilityMetrics|Filter dimensions...'),
  },
  props: {
    searchConfig: {
      type: Object,
      required: true,
    },
  },
  data() {
    const defaultRange = periodToDate(DEFAULT_TIME_RANGE);
    return {
      shouldShowDateRangePicker: false,
      dimensionFilters: [],
      dateRange: {
        value: DEFAULT_TIME_RANGE,
        startDarte: defaultRange.min,
        endDate: defaultRange.max,
      },
      groupBy: {
        dimensions: this.searchConfig.defaultGroupByDimensions ?? [],
        func: this.searchConfig.defaultGroupByFunction ?? '',
      },
    };
  },
  computed: {
    availableTokens() {
      return this.searchConfig.dimensions.map((dimension) => ({
        title: dimension,
        type: dimension,
        token: GlFilteredSearchToken,
        operators: [...OPERATORS_IS_NOT, ...OPERATORS_LIKE_NOT],
      }));
    },
  },
  methods: {
    onFilter(filters) {
      this.dimensionFilters = filters;

      this.$emit('filter', {
        dimensions: this.dimensionFilters,
        dateRange: this.dateRange,
        groupBy: this.groupBy,
      });
    },
    onDateRangeSelected({ value, startDate, endDate }) {
      this.dateRange = { value, startDate, endDate };
    },
    onGroupBy({ dimensions, func }) {
      this.groupBy = { dimensions, func };
    },
  },
};
</script>

<template>
  <div
    class="gl-mt-3 gl-mb-9 gl-py-5 gl-px-3 gl-bg-gray-10 gl-border-b-1 gl-border-b-solid gl-border-t-1 gl-border-t-solid gl-border-gray-100"
  >
    <filtered-search
      class="filtered-search-box gl-display-flex gl-border-none"
      recent-searches-storage-key="recent-metrics-filter-search"
      namespace="metrics-details-filtered-search"
      :search-input-placeholder="$options.i18n.searchInputPlaceholder"
      :tokens="availableTokens"
      terms-as-tokens
      @onFilter="onFilter"
    />

    <hr class="gl-my-3" />

    <date-range-filter :selected="dateRange" @onDateRangeSelected="onDateRangeSelected" />

    <hr class="gl-my-3" />

    <group-by-filter
      :search-config="searchConfig"
      :selected-dimensions="groupBy.dimensions"
      :selected-function="groupBy.func"
      @groupBy="onGroupBy"
    />
  </div>
</template>
