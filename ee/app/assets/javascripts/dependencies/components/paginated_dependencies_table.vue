<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';
import { DEPENDENCY_LIST_TYPES } from '../store/constants';
import DependenciesTable from './dependencies_table.vue';

export default {
  name: 'PaginatedDependenciesTable',
  components: {
    DependenciesTable,
    TablePagination,
  },
  inject: ['vulnerabilitiesEndpoint'],
  props: {
    namespace: {
      type: String,
      required: true,
      validator: (value) =>
        Object.values(DEPENDENCY_LIST_TYPES).some(({ namespace }) => value === namespace),
    },
  },
  computed: {
    ...mapState({
      module(state) {
        return state[this.namespace];
      },
      shouldShowPagination() {
        const { isLoading, errorLoading, pageInfo } = this.module;
        return Boolean(!isLoading && !errorLoading && pageInfo);
      },
    }),
  },
  methods: {
    ...mapActions({
      fetchPage(dispatch, page) {
        return dispatch(`${this.namespace}/fetchDependencies`, { page });
      },
      fetchVulnerabilities(dispatch, item) {
        return dispatch(`${this.namespace}/fetchVulnerabilities`, {
          item,
          vulnerabilitiesEndpoint: this.vulnerabilitiesEndpoint,
        });
      },
    }),
  },
};
</script>

<template>
  <div>
    <dependencies-table
      :dependencies="module.dependencies"
      :vulnerability-info="module.vulnerabilityInfo"
      :vulnerability-items-loading="module.vulnerabilityItemsLoading"
      :is-loading="module.isLoading"
      @row-click="fetchVulnerabilities"
    />

    <table-pagination
      v-if="shouldShowPagination"
      :change="fetchPage"
      :page-info="module.pageInfo"
      align="center"
    />
  </div>
</template>
