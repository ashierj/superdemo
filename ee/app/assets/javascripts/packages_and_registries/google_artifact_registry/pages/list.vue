<script>
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import ListHeader from 'ee_component/packages_and_registries/google_artifact_registry/components/list/header.vue';
import getArtifactsQuery from 'ee_component/packages_and_registries/google_artifact_registry/graphql/queries/get_artifacts.query.graphql';

export default {
  name: 'ArtifactRegistryListPage',
  components: {
    ListHeader,
  },
  inject: ['fullPath'],
  apollo: {
    artifacts: {
      query: getArtifactsQuery,
      variables() {
        return {
          fullPath: this.fullPath,
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
      const { project, repository, gcpRepositoryUrl } = this.artifacts;
      if (project && repository) {
        return {
          project,
          repository,
          gcpRepositoryUrl,
        };
      }
      return {};
    },
    isLoading() {
      return this.$apollo.queries.artifacts.loading;
    },
  },
};
</script>

<template>
  <div data-testid="artifact-registry-list-page">
    <list-header :data="headerData" :is-loading="isLoading" :show-error="failedToLoad" />
  </div>
</template>
