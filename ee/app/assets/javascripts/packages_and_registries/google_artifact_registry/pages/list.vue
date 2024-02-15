<script>
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import ListHeader from 'ee_component/packages_and_registries/google_artifact_registry/components/list/header.vue';
import ListTable from 'ee_component/packages_and_registries/google_artifact_registry/components/list/table.vue';
import getArtifactsQuery from 'ee_component/packages_and_registries/google_artifact_registry/graphql/queries/get_artifacts.query.graphql';

const PAGE_SIZE = 20;

export default {
  name: 'ArtifactRegistryListPage',
  components: {
    ListHeader,
    ListTable,
  },
  inject: ['fullPath'],
  apollo: {
    artifacts: {
      query: getArtifactsQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data.project?.googleCloudPlatformArtifactRegistryRepositoryArtifacts ?? {};
      },
      error(error) {
        this.failedToLoad = true;
        Sentry.captureException(error);
      },
    },
  },
  data() {
    return {
      artifacts: {},
      sort: {
        sortBy: 'updateTime',
        sortDesc: true,
      },
      failedToLoad: false,
    };
  },
  computed: {
    headerData() {
      const { projectId, repository, gcpRepositoryUrl } = this.artifacts;
      if (projectId && repository) {
        return {
          projectId,
          repository,
          gcpRepositoryUrl,
        };
      }
      return {};
    },
    isLoading() {
      return this.$apollo.queries.artifacts.loading;
    },
    queryVariables() {
      return {
        first: PAGE_SIZE,
        fullPath: this.fullPath,
        sort: this.sortString,
      };
    },
    sortString() {
      return this.sort.sortDesc ? 'UPDATE_TIME_DESC' : 'UPDATE_TIME_ASC';
    },
    tableData() {
      const { nodes = [] } = this.artifacts;
      return {
        nodes,
      };
    },
  },
  methods: {
    onSort(sort) {
      this.sort = sort;
    },
  },
};
</script>

<template>
  <div data-testid="artifact-registry-list-page">
    <list-header :data="headerData" :is-loading="isLoading" :show-error="failedToLoad" />
    <list-table
      v-if="!failedToLoad"
      :data="tableData"
      :sort="sort"
      :is-loading="isLoading"
      @sort-changed="onSort"
    />
  </div>
</template>
