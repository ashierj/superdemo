<script>
import { captureException } from '~/ci/runner/sentry_utils';
import { convertToSnakeCase } from '~/lib/utils/text_utility';
import CeNamespaceStorageApp from '~/usage_quotas/storage/components/namespace_storage_app.vue';
import NamespaceStorageQuery from '../queries/namespace_storage.query.graphql';
import ProjectListStorageQuery from '../queries/project_list_storage.query.graphql';
import { parseGetStorageResults } from '../utils';

export default {
  name: 'NamespaceStorageApp',
  components: {
    CeNamespaceStorageApp,
  },
  inject: [
    'namespaceId',
    'namespacePath',
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
  data() {
    return {
      namespace: {},
      projects: null,
      searchTerm: '',
      namespaceLoadingError: false,
      projectsLoadingError: false,
      sortKey: this.isUsingProjectEnforcementWithLimits ? 'STORAGE' : 'STORAGE_SIZE_DESC',
    };
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
  },
};
</script>
<template>
  <ce-namespace-storage-app
    :projects-loading-error="projectsLoadingError"
    :namespace-loading-error="namespaceLoadingError"
    :is-namespace-storage-statistics-loading="$apollo.queries.namespace.loading"
    :is-namespace-projects-loading="$apollo.queries.projects.loading"
    :namespace="namespace"
    :projects="projects"
    :initial-sort-by="isUsingProjectEnforcementWithLimits ? null : 'storage'"
    @search="onSearch"
    @sort-changed="onSortChanged"
    @fetch-more-projects="fetchMoreProjects"
  />
</template>
