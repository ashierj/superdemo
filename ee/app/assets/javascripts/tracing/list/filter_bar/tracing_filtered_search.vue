<script>
import { GlFilteredSearchToken } from '@gitlab/ui';
import { s__ } from '~/locale';
import {
  OPERATORS_IS,
  OPERATORS_IS_NOT,
} from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearch from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import { SORTING_OPTIONS } from '~/observability/constants';
import {
  PERIOD_FILTER_TOKEN_TYPE,
  SERVICE_NAME_FILTER_TOKEN_TYPE,
  OPERATION_FILTER_TOKEN_TYPE,
  TRACE_ID_FILTER_TOKEN_TYPE,
  DURATION_MS_FILTER_TOKEN_TYPE,
  ATTRIBUTE_FILTER_TOKEN_TYPE,
} from './filters';
import ServiceToken from './service_search_token.vue';
import OperationToken from './operation_search_token.vue';
import AttributeSearchToken from './attribute_search_token.vue';

export default {
  components: {
    FilteredSearch,
  },
  i18n: {
    searchInputPlaceholder: s__('Tracing|Filter traces'),
  },
  props: {
    initialFilters: {
      type: Array,
      required: false,
      default: () => [],
    },
    observabilityClient: {
      required: true,
      type: Object,
    },
    initialSort: {
      required: true,
      type: String,
    },
  },
  computed: {
    sortOptions() {
      return [
        {
          id: 1,
          title: s__('Tracing|Duration'),
          sortDirection: {
            ascending: SORTING_OPTIONS.DURATION_ASC,
            descending: SORTING_OPTIONS.DURATION_DESC,
          },
        },
        {
          id: 2,
          title: s__('Tracing|Timestamp'),
          sortDirection: {
            ascending: SORTING_OPTIONS.TIMESTAMP_ASC,
            descending: SORTING_OPTIONS.TIMESTAMP_DESC,
          },
        },
      ];
    },
    availableTokens() {
      return [
        {
          title: s__('Tracing|Time range'),
          icon: 'clock',
          type: PERIOD_FILTER_TOKEN_TYPE,
          token: GlFilteredSearchToken,
          operators: OPERATORS_IS,
          unique: true,
          options: [
            { value: '5m', title: s__('Tracing|Last 5 minutes') },
            { value: '15m', title: s__('Tracing|Last 15 minutes') },
            { value: '30m', title: s__('Tracing|Last 30 minutes') },
            { value: '1h', title: s__('Tracing|Last 1 hour') },
            { value: '4h', title: s__('Tracing|Last 4 hours') },
            { value: '12h', title: s__('Tracing|Last 12 hours') },
            { value: '24h', title: s__('Tracing|Last 24 hours') },
            { value: '7d', title: s__('Tracing|Last 7 days') },
            { value: '14d', title: s__('Tracing|Last 14 days') },
            { value: '30d', title: s__('Tracing|Last 30 days') },
          ],
        },
        {
          title: s__('Tracing|Service'),
          type: SERVICE_NAME_FILTER_TOKEN_TYPE,
          token: ServiceToken,
          operators: OPERATORS_IS_NOT,
          fetchServices: this.observabilityClient.fetchServices,
        },
        {
          title: s__('Tracing|Operation'),
          type: OPERATION_FILTER_TOKEN_TYPE,
          token: OperationToken,
          operators: OPERATORS_IS_NOT,
          fetchOperations: this.observabilityClient.fetchOperations,
        },
        {
          title: s__('Tracing|Trace ID'),
          type: TRACE_ID_FILTER_TOKEN_TYPE,
          token: GlFilteredSearchToken,
          operators: OPERATORS_IS_NOT,
        },
        {
          title: s__('Tracing|Duration (ms)'),
          type: DURATION_MS_FILTER_TOKEN_TYPE,
          token: GlFilteredSearchToken,
          operators: [
            { value: '>', description: s__('Tracing|longer than') },
            { value: '<', description: s__('Tracing|shorter than') },
          ],
        },
        {
          title: s__('Tracing|Attribute'),
          type: ATTRIBUTE_FILTER_TOKEN_TYPE,
          token: AttributeSearchToken,
          operators: OPERATORS_IS,
        },
      ];
    },
  },
};
</script>

<template>
  <div class="vue-filtered-search-bar-container gl-border-t-none gl-my-6">
    <filtered-search
      recent-searches-storage-key="recent-tracing-filter-search"
      :initial-sort-by="initialSort"
      namespace="tracing-list-filtered-search"
      :search-input-placeholder="$options.i18n.searchInputPlaceholder"
      :tokens="availableTokens"
      :initial-filter-value="initialFilters"
      terms-as-tokens
      :sort-options="sortOptions"
      @onFilter="$emit('submit', $event)"
      @onSort="$emit('sort', $event)"
    />
  </div>
</template>
