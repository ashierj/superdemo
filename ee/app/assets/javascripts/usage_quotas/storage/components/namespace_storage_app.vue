<script>
import { GlKeysetPagination } from '@gitlab/ui';
import { captureException } from '~/ci/runner/sentry_utils';
import { convertToSnakeCase } from '~/lib/utils/text_utility';
import { __ } from '~/locale';
import CeNamespaceStorageApp from '~/usage_quotas/storage/components/namespace_storage_app.vue';
import NamespaceStorageQuery from '../queries/namespace_storage.query.graphql';
import ProjectListStorageQuery from '../queries/project_list_storage.query.graphql';
import { parseGetStorageResults } from '../utils';
import { NAMESPACE_STORAGE_BREAKDOWN_SUBTITLE } from '../constants';
import SearchAndSortBar from '../../components/search_and_sort_bar/search_and_sort_bar.vue';
import ProjectList from './project_list.vue';
import DependencyProxyUsage from './dependency_proxy_usage.vue';
import ContainerRegistryUsage from './container_registry_usage.vue';

export default {
  name: 'NamespaceStorageApp',
  components: {
    GlKeysetPagination,
    CeNamespaceStorageApp,
    ProjectList,
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
        };
      },
      update: parseGetStorageResults,
      error(error) {
        this.namespaceLoadingError = true;
        captureException({ error, component: this.$options.name });
      },
    },
    projects: {
      query: ProjectListStorageQuery,
      variables() {
        return {
          fullPath: this.namespacePath,
          searchTerm: this.searchTerm,
          first: this.defaultPerPage,
          sortKey: this.sortKey,
        };
      },
      update(data) {
        return data.namespace.projects;
      },
      error(error) {
        this.projectsLoadingError = true;
        captureException({ error, component: this.$options.name });
      },
    },
  },
  i18n: {
    NAMESPACE_STORAGE_BREAKDOWN_SUBTITLE,
    search: __('Search'),
  },
  data() {
    return {
      namespace: {},
      projects: null,
      searchTerm: '',
      namespaceLoadingError: false,
      projectsLoadingError: false,
      sortKey: this.isUsingProjectEnforcementWithLimits ? 'STORAGE' : 'STORAGE_SIZE_DESC',
      initialSortBy: this.isUsingProjectEnforcementWithLimits ? null : 'storage',
    };
  },
  computed: {
    containerRegistrySize() {
      return this.namespace.rootStorageStatistics?.containerRegistrySize ?? 0;
    },
    containerRegistrySizeIsEstimated() {
      return this.namespace.rootStorageStatistics?.containerRegistrySizeIsEstimated ?? false;
    },
    dependencyProxyTotalSize() {
      return this.namespace.rootStorageStatistics?.dependencyProxySize ?? 0;
    },
    projectList() {
      return this.projects?.nodes ?? [];
    },
    pageInfo() {
      return this.projects?.pageInfo;
    },
    showPagination() {
      return Boolean(this.pageInfo?.hasPreviousPage || this.pageInfo?.hasNextPage);
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
      this.$apollo.queries.projects.fetchMore({
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
  <ce-namespace-storage-app
    :projects-loading-error="projectsLoadingError"
    :namespace-loading-error="namespaceLoadingError"
    :is-namespace-storage-statistics-loading="$apollo.queries.namespace.loading"
    :namespace="namespace"
  >
    <template #ee-storage-app>
      <h3 data-testid="breakdown-subtitle">
        {{ $options.i18n.NAMESPACE_STORAGE_BREAKDOWN_SUBTITLE }}
      </h3>
      <dependency-proxy-usage
        v-if="!userNamespace"
        :dependency-proxy-total-size="dependencyProxyTotalSize"
        :loading="$apollo.queries.namespace.loading"
      />
      <container-registry-usage
        :container-registry-size="containerRegistrySize"
        :container-registry-size-is-estimated="containerRegistrySizeIsEstimated"
        :loading="$apollo.queries.namespace.loading"
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
          :projects="projectList"
          :is-loading="$apollo.queries.projects.loading"
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
    </template>
  </ce-namespace-storage-app>
</template>
