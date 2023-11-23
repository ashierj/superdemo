<script>
import { GlAlert, GlKeysetPagination } from '@gitlab/ui';
import { captureException } from '~/ci/runner/sentry_utils';
import { convertToSnakeCase } from '~/lib/utils/text_utility';
import { __ } from '~/locale';
import NamespaceStorageQuery from '../queries/namespace_storage.query.graphql';
import { parseGetStorageResults } from '../utils';
import {
  NAMESPACE_STORAGE_ERROR_MESSAGE,
  NAMESPACE_STORAGE_BREAKDOWN_SUBTITLE,
} from '../constants';
import SearchAndSortBar from '../../components/search_and_sort_bar/search_and_sort_bar.vue';
import ProjectList from './project_list.vue';
import DependencyProxyUsage from './dependency_proxy_usage.vue';
import StorageUsageStatistics from './storage_usage_statistics.vue';
import ContainerRegistryUsage from './container_registry_usage.vue';

export default {
  name: 'NamespaceStorageApp',
  components: {
    GlAlert,
    ProjectList,
    StorageUsageStatistics,
    GlKeysetPagination,
    DependencyProxyUsage,
    ContainerRegistryUsage,
    SearchAndSortBar,
  },
  inject: [
    'namespaceId',
    'namespacePath',
    'helpLinks',
    'defaultPerPage',
    'userNamespace',
    'isUsingProjectEnforcementWithLimits',
  ],
  apollo: {
    namespace: {
      query: NamespaceStorageQuery,
      variables() {
        return {
          fullPath: this.namespacePath,
          searchTerm: this.searchTerm,
          first: this.defaultPerPage,
          sortKey: this.sortKey,
        };
      },
      update: parseGetStorageResults,
      result() {
        this.firstFetch = false;
      },
      error(error) {
        this.loadingError = true;
        captureException({ error, component: this.$options.name });
      },
    },
  },
  i18n: {
    NAMESPACE_STORAGE_ERROR_MESSAGE,
    NAMESPACE_STORAGE_BREAKDOWN_SUBTITLE,
    search: __('Search'),
  },
  data() {
    return {
      namespace: {},
      searchTerm: '',
      firstFetch: true,
      loadingError: false,
      sortKey: this.isUsingProjectEnforcementWithLimits ? 'STORAGE' : 'STORAGE_SIZE_DESC',
      initialSortBy: this.isUsingProjectEnforcementWithLimits ? null : 'storage',
    };
  },
  computed: {
    namespaceProjects() {
      return this.namespace.projects?.data ?? [];
    },
    costFactoredStorageSize() {
      return this.namespace.rootStorageStatistics?.costFactoredStorageSize;
    },
    containerRegistrySize() {
      return this.namespace.rootStorageStatistics?.containerRegistrySize ?? 0;
    },
    containerRegistrySizeIsEstimated() {
      return this.namespace.rootStorageStatistics?.containerRegistrySizeIsEstimated ?? false;
    },
    dependencyProxyTotalSize() {
      return this.namespace.rootStorageStatistics?.dependencyProxySize ?? 0;
    },
    pageInfo() {
      return this.namespace.projects?.pageInfo ?? {};
    },
    showPagination() {
      return Boolean(this.pageInfo?.hasPreviousPage || this.pageInfo?.hasNextPage);
    },
    isQueryLoading() {
      return this.$apollo.queries.namespace.loading;
    },
    isStorageUsageStatisticsLoading() {
      return this.loadingError || this.isQueryLoading;
    },
  },
  methods: {
    onSearch(searchTerm) {
      if (searchTerm?.length < 3) {
        // NOTE: currently the API doesn't handle strings of length < 3,
        // returning an empty list as a result of such searches. So here we
        // substitute short search terms with empty string to simulate default
        // "fetch all" behaviour.
        this.searchTerm = '';
      } else {
        this.searchTerm = searchTerm;
      }
    },
    onSortChanged({ sortBy, sortDesc }) {
      if (sortBy !== 'storage') {
        return;
      }

      const sortDir = sortDesc ? 'desc' : 'asc';
      const sortKey = `${convertToSnakeCase(sortBy)}_size_${sortDir}`.toUpperCase();
      this.sortKey = sortKey;
    },
    fetchMoreProjects(vars) {
      this.$apollo.queries.namespace.fetchMore({
        variables: {
          fullPath: this.namespacePath,
          ...vars,
        },
        updateQuery(previousResult, { fetchMoreResult }) {
          return fetchMoreResult;
        },
      });
    },
    onPrev(before) {
      if (this.pageInfo?.hasPreviousPage) {
        this.fetchMoreProjects({ before, last: this.defaultPerPage, first: undefined });
      }
    },
    onNext(after) {
      if (this.pageInfo?.hasNextPage) {
        this.fetchMoreProjects({ after, first: this.defaultPerPage });
      }
    },
  },
};
</script>
<template>
  <div>
    <gl-alert v-if="loadingError" variant="danger" :dismissible="false" class="gl-mt-4">
      {{ $options.i18n.NAMESPACE_STORAGE_ERROR_MESSAGE }}
    </gl-alert>
    <storage-usage-statistics
      :additional-purchased-storage-size="namespace.additionalPurchasedStorageSize"
      :used-storage="costFactoredStorageSize"
      :loading="isStorageUsageStatisticsLoading"
    />

    <h3 data-testid="breakdown-subtitle">
      {{ $options.i18n.NAMESPACE_STORAGE_BREAKDOWN_SUBTITLE }}
    </h3>
    <dependency-proxy-usage
      v-if="!userNamespace"
      :dependency-proxy-total-size="dependencyProxyTotalSize"
      :loading="isQueryLoading"
    />
    <container-registry-usage
      :container-registry-size="containerRegistrySize"
      :container-registry-size-is-estimated="containerRegistrySizeIsEstimated"
      :loading="isQueryLoading"
    />

    <section class="gl-mt-5">
      <div class="gl-bg-gray-10 gl-p-5 gl-display-flex">
        <search-and-sort-bar
          :namespace="namespaceId"
          :search-input-placeholder="$options.i18n.search"
          @onFilter="onSearch"
        />
      </div>

      <project-list
        :projects="namespaceProjects"
        :is-loading="isQueryLoading"
        :help-links="helpLinks"
        :sort-by="initialSortBy"
        :sort-desc="true"
        @sortChanged="onSortChanged($event)"
      />

      <div class="gl-display-flex gl-justify-content-center gl-mt-5">
        <gl-keyset-pagination
          v-if="showPagination"
          v-bind="pageInfo"
          @prev="onPrev"
          @next="onNext"
        />
      </div>
    </section>
  </div>
</template>
