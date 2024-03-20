<script>
import { updateHistory, getParameterByName, setUrlParams } from '~/lib/utils/url_utility';
import getSecretsQuery from '../graphql/queries/client/get_secrets.query.graphql';
import { INITIAL_PAGE, PAGE_SIZE } from '../constants';

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
      page: INITIAL_PAGE,
    };
  },
  computed: {
    queryVariables() {
      return {
        fullPath: this.projectPath,
        isProject: true,
        offset: (this.page - 1) * PAGE_SIZE,
        limit: PAGE_SIZE,
      };
    },
  },
  apollo: {
    secrets: {
      query: getSecretsQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data.project.secrets || {};
      },
    },
  },
  created() {
    this.updateQueryParamsFromUrl();

    window.addEventListener('popstate', this.updateQueryParamsFromUrl);
  },
  destroyed() {
    window.removeEventListener('popstate', this.updateQueryParamsFromUrl);
  },
  methods: {
    updateQueryParamsFromUrl() {
      this.page = Number(getParameterByName('page')) || INITIAL_PAGE;
    },
    handlePageChange(page) {
      this.page = page;
      updateHistory({
        url: setUrlParams({ page }),
      });
    },
  },
};
</script>
<template>
  <router-view ref="router-view" :secrets="secrets" :page="page" @onPageChange="handlePageChange" />
</template>
