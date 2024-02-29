<script>
import getProjectSecretsQuery from '../graphql/queries/client/get_project_secrets.query.graphql';
import { PAGE_SIZE } from '../constants';

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
  data() {
    return {
      offset: 0,
    };
  },
  computed: {
    queryVariables() {
      return {
        fullPath: this.projectPath,
        offset: this.offset,
        limit: PAGE_SIZE,
      };
    },
  },
  apollo: {
    secrets: {
      query: getProjectSecretsQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data.project.secrets || {};
      },
    },
  },
  methods: {
    handlePageChange(page) {
      this.offset = (page - 1) * PAGE_SIZE;
      this.$apollo.queries.secrets.fetchMore(this.queryVariables);
    },
  },
};
</script>
<template>
  <router-view ref="router-view" :secrets="secrets" @onPageChange="handlePageChange" />
</template>
