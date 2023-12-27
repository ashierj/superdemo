<script>
import { GlAlert, GlKeysetPagination } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { fetchPolicies } from '~/lib/graphql';
import { s__ } from '~/locale';

import complianceFrameworks from 'ee/graphql_shared/queries/get_compliance_framework.query.graphql';
import FrameworksTable from './frameworks_table.vue';

const FRAMEWORK_LIMIT = 20;

export default {
  name: 'ComplianceProjectsReport',
  components: {
    GlAlert,
    GlKeysetPagination,
    FrameworksTable,
  },
  props: {
    groupPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      hasQueryError: false,
      frameworks: { nodes: [] },
      searchString: '',
      cursor: {
        before: null,
        after: null,
      },
    };
  },
  apollo: {
    frameworks: {
      query: complianceFrameworks,
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      variables() {
        return {
          fullPath: this.groupPath,
          search: this.searchString,
          ...this.cursor,
          [this.cursor.before ? 'last' : 'first']: FRAMEWORK_LIMIT,
        };
      },
      update(data) {
        return data.namespace.complianceFrameworks;
      },
      error(e) {
        Sentry.captureException(e);
        this.hasQueryError = true;
      },
    },
  },
  computed: {
    isLoading() {
      return Boolean(this.$apollo.queries.frameworks.loading);
    },
  },
  methods: {
    onPrevPage() {
      this.cursor = {
        before: this.frameworks.pageInfo.startCursor,
        after: null,
      };
    },

    onNextPage() {
      this.cursor = {
        after: this.frameworks.pageInfo.endCursor,
        before: null,
      };
    },

    onSearch(searchString) {
      this.cursor = {
        before: null,
        after: null,
      };
      this.searchString = searchString;
    },
  },
  i18n: {
    queryError: s__(
      'ComplianceReport|Unable to load the compliance framework report. Refresh the page and try again.',
    ),
  },
};
</script>

<template>
  <section class="gl-display-flex gl-flex-direction-column">
    <gl-alert v-if="hasQueryError" variant="danger" class="gl-my-3" :dismissible="false">
      {{ $options.i18n.queryError }}
    </gl-alert>

    <template v-else>
      <frameworks-table :is-loading="isLoading" :frameworks="frameworks.nodes" @search="onSearch" />
      <gl-keyset-pagination
        v-bind="frameworks.pageInfo"
        class="gl-align-self-center gl-mt-6"
        :prev-text="__('Prev')"
        :next-text="__('Next')"
        @prev="onPrevPage"
        @next="onNextPage"
      />
    </template>
  </section>
</template>
