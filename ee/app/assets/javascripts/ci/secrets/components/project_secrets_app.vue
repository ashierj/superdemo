<script>
import getProjectSecretsQuery from '../graphql/queries/client/get_project_secrets.query.graphql';

export default {
  name: 'ProjectSecretsApp',
  props: {
    projectPath: {
      type: String,
      required: false,
      default: undefined,
    },
    projectId: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  apollo: {
    secrets: {
      query: getProjectSecretsQuery,
      variables() {
        return {
          fullPath: this.projectPath,
        };
      },
      update(data) {
        return data.project.secrets.nodes || [];
      },
    },
  },
};
</script>
<template>
  <router-view ref="router-view" :secrets="secrets" />
</template>
