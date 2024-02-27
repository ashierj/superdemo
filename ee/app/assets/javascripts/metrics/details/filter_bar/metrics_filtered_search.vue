<script>
import { GlFilteredSearchToken, GlButton, GlLoadingIcon } from '@gitlab/ui';

import { s__ } from '~/locale';
import { OPERATORS_IS_NOT } from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearch from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import { OPERATORS_LIKE_NOT } from '~/observability/constants';
import DateRangeFilter from './date_range_filter.vue';
import GroupByFilter from './groupby_filter.vue';

export default {
  components: {
    FilteredSearch,
    DateRangeFilter,
    GroupByFilter,
    GlButton,
    GlLoadingIcon,
  },
  i18n: {
    searchInputPlaceholder: s__('ObservabilityMetrics|Filter attributes...'),
    search: s__('ObservabilityMetrics|Search'),
    cancel: s__('ObservabilityMetrics|Cancel'),
  },
  props: {
    searchMetadata: {
      type: Object,
      required: true,
    },
    attributeFilters: {
      type: Array,
      required: false,
      default: () => [],
    },
    dateRangeFilter: {
      type: Object,
      required: false,
      default: () => {},
    },
    groupByFilter: {
      type: Object,
      required: false,
      default: () => {},
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    let defaultGroupByAttributes = this.searchMetadata.default_group_by_attributes ?? [];
    if (defaultGroupByAttributes.length === 1 && defaultGroupByAttributes[0] === '*') {
      defaultGroupByAttributes = [...(this.searchMetadata.attribute_keys ?? [])];
    }
    return {
      shouldShowDateRangePicker: false,
      filters: this.attributeFilters,
      dateRange: this.dateRangeFilter,
      groupBy: {
        attributes: this.groupByFilter?.attributes ?? defaultGroupByAttributes,
        func: this.groupByFilter?.func ?? this.searchMetadata.default_group_by_function,
      },
    };
  },
  computed: {
    availableTokens() {
      return this.searchMetadata.attribute_keys.map((attribute) => ({
        title: attribute,
        type: attribute,
        token: GlFilteredSearchToken,
        operators: [...OPERATORS_IS_NOT, ...OPERATORS_LIKE_NOT],
      }));
    },
  },
  methods: {
    onFilter(filters) {
      this.filters = filters;
    },
    onDateRangeSelected({ value, startDate, endDate }) {
      this.dateRange = { value, startDate, endDate };
    },
    onGroupBy({ attributes, func }) {
      this.groupBy = { attributes, func };
    },
    onSubmit() {
      if (this.loading) {
        this.$emit('cancel');
      } else {
        this.$emit('submit', {
          attributes: this.filters,
          dateRange: this.dateRange,
          groupBy: this.groupBy,
        });
      }
    },
  },
};
</script>

<template>
  <div
    class="gl-mt-3 gl-mb-6 gl-py-5 gl-px-3 gl-bg-gray-10 gl-border-b-1 gl-border-b-solid gl-border-t-1 gl-border-t-solid gl-border-gray-100"
  >
    <filtered-search
      class="filtered-search-box gl-display-flex gl-border-none"
      recent-searches-storage-key="recent-metrics-filter-search"
      namespace="metrics-details-filtered-search"
      :search-input-placeholder="$options.i18n.searchInputPlaceholder"
      :tokens="availableTokens"
      :initial-filter-value="filters"
      terms-as-tokens
      :show-search-button="false"
      @onFilter="onFilter"
    />

    <hr class="gl-my-3" />

    <date-range-filter :selected="dateRange" @onDateRangeSelected="onDateRangeSelected" />

    <hr class="gl-my-3" />

    <group-by-filter
      :supported-functions="searchMetadata.supported_functions"
      :supported-attributes="searchMetadata.attribute_keys"
      :selected-attributes="groupBy.attributes"
      :selected-function="groupBy.func"
      @groupBy="onGroupBy"
    />

    <gl-button
      type="submit"
      :variant="loading ? 'danger' : 'confirm'"
      class="gl-my-5 gl-mb-0!"
      @click="onSubmit"
    >
      <template v-if="loading">
        <gl-loading-icon size="sm" inline color="light" />
        {{ $options.i18n.cancel }}
      </template>
      <template v-else>
        {{ $options.i18n.search }}
      </template>
    </gl-button>
  </div>
</template>
