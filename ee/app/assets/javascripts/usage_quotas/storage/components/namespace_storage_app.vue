<script>
import { GlKeysetPagination } from '@gitlab/ui';
import { captureException } from '~/ci/runner/sentry_utils';
import { convertToSnakeCase } from '~/lib/utils/text_utility';
import CeNamespaceStorageApp from '~/usage_quotas/storage/components/namespace_storage_app.vue';
import NamespaceStorageQuery from '../queries/namespace_storage.query.graphql';
import ProjectListStorageQuery from '../queries/project_list_storage.query.graphql';
import { parseGetStorageResults } from '../utils';
import ProjectList from './project_list.vue';

export default {
  name: 'NamespaceStorageApp',
  components: {
    GlKeysetPagination,
    CeNamespaceStorageApp,
    ProjectList,
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
    @search="onSearch($event)"
  >
    <template #ee-storage-app>
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
    </template>
  </ce-namespace-storage-app>
</template>
