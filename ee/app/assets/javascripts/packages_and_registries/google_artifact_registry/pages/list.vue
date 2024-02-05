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
        return {
          fullPath: this.fullPath,
          first: PAGE_SIZE,
        };
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
    tableData() {
      const { nodes = [] } = this.artifacts;
      return {
        nodes,
      };
    },
  },
};
</script>

<template>
  <div data-testid="artifact-registry-list-page">
    <list-header :data="headerData" :is-loading="isLoading" :show-error="failedToLoad" />
    <list-table v-if="!failedToLoad" :data="tableData" :is-loading="isLoading" />
  </div>
</template>
