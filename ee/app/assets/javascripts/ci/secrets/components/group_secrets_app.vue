<script>
import { updateHistory, getParameterByName, setUrlParams } from '~/lib/utils/url_utility';
import getGroupSecretsQuery from '../graphql/queries/client/get_group_secrets.query.graphql';
import { INITIAL_PAGE, PAGE_SIZE } from '../constants';

export default {
  name: 'GroupSecretsApp',
  props: {
    groupPath: {
      type: String,
      required: false,
      default: undefined,
    },
    groupId: {
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
        fullPath: this.groupPath,
        offset: (this.page - 1) * PAGE_SIZE,
        limit: PAGE_SIZE,
      };
    },
  },
  apollo: {
    secrets: {
      query: getGroupSecretsQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data.group.secrets || {};
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
