<script>
import { GlAlert, GlTable, GlIcon, GlLink, GlBadge, GlLoadingIcon } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { formatDate } from '~/lib/utils/datetime_utility';
import getProjectComplianceStandardsAdherence from '../../graphql/compliance_standards_adherence.query.graphql';
import Pagination from '../shared/pagination.vue';
import { GRAPHQL_PAGE_SIZE } from '../../constants';
import {
  FAIL_STATUS,
  STANDARDS_ADHERENCE_CHECK_LABELS,
  STANDARDS_ADHERENCE_CHECK_DESCRIPTIONS,
  STANDARDS_ADHERENCE_STANARD_LABELS,
  NO_STANDARDS_ADHERENCES_FOUND,
  STANDARDS_ADHERENCE_FETCH_ERROR,
} from './constants';
import FixSuggestionsSidebar from './fix_suggestions_sidebar.vue';

const columnWidth = 'gl-md-max-w-26 gl-white-space-nowrap';

export default {
  name: 'ComplianceStandardsAdherenceTable',
  components: {
    GlAlert,
    GlTable,
    GlIcon,
    GlLink,
    GlBadge,
    GlLoadingIcon,
    FixSuggestionsSidebar,
    Pagination,
  },
  props: {
    groupPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      hasStandardsAdherenceFetchError: false,
      adherences: {
        list: [],
        pageInfo: {},
      },
      drawerId: null,
      drawerAdherence: {},
    };
  },
  apollo: {
    adherences: {
      query: getProjectComplianceStandardsAdherence,
      variables() {
        return {
          fullPath: this.groupPath,
          ...this.paginationCursors,
        };
      },
      update(data) {
        const { nodes, pageInfo } = data?.group?.projectComplianceStandardsAdherence || {};
        return {
          list: nodes,
          pageInfo,
        };
      },
      error(e) {
        Sentry.captureException(e);
        this.hasStandardsAdherenceFetchError = true;
      },
    },
  },
  computed: {
    isLoading() {
      return Boolean(this.$apollo.queries.adherences.loading);
    },
    showDrawer() {
      return this.drawerId !== null;
    },
    showPagination() {
      const { hasPreviousPage, hasNextPage } = this.adherences.pageInfo || {};
      return hasPreviousPage || hasNextPage;
    },
    paginationCursors() {
      const { before, after } = this.$route.query;

      if (before) {
        return {
          before,
          last: this.perPage,
        };
      }

      return {
        after,
        first: this.perPage,
      };
    },
    perPage() {
      return parseInt(this.$route.query.perPage || GRAPHQL_PAGE_SIZE, 10);
    },
  },
  methods: {
    adherenceCheckName(check) {
      return STANDARDS_ADHERENCE_CHECK_LABELS[check];
    },
    adherenceCheckDescription(check) {
      return STANDARDS_ADHERENCE_CHECK_DESCRIPTIONS[check];
    },
    adherenceStandardLabel(standard) {
      return STANDARDS_ADHERENCE_STANARD_LABELS[standard];
    },
    formatDate(dateString) {
      return formatDate(dateString, 'mmm d, yyyy');
    },
    isFailedStatus(status) {
      return status === FAIL_STATUS;
    },
    toggleDrawer(item) {
      if (this.drawerId === item.id) {
        this.closeDrawer();
      } else {
        this.openDrawer(item);
      }
    },
    openDrawer(item) {
      this.drawerAdherence = item;
      this.drawerId = item.id;
    },
    closeDrawer() {
      this.drawerAdherence = {};
      this.drawerId = null;
    },
    loadPrevPage(startCursor) {
      this.$router.push({
        query: {
          ...this.$route.query,
          before: startCursor,
          after: undefined,
        },
      });
    },
    loadNextPage(endCursor) {
      this.$router.push({
        query: {
          ...this.$route.query,
          before: undefined,
          after: endCursor,
        },
      });
    },
    onPageSizeChange(perPage) {
      this.$router.push({
        query: {
          ...this.$route.query,
          before: undefined,
          after: undefined,
          perPage,
        },
      });
    },
  },
  fields: [
    {
      key: 'status',
      sortable: false,
      thClass: columnWidth,
      tdClass: columnWidth,
    },
    {
      key: 'project',
      sortable: false,
      tdClass: columnWidth,
    },
    {
      key: 'checks',
      sortable: false,
    },
    {
      key: 'standard',
      sortable: false,
      thClass: columnWidth,
      tdClass: columnWidth,
    },
    {
      key: 'lastScanned',
      sortable: false,
      thClass: columnWidth,
      tdClass: columnWidth,
    },
    {
      key: 'fixSuggestions',
      sortable: false,
      thClass: columnWidth,
      tdClass: columnWidth,
    },
  ],
  noStandardsAdherencesFound: NO_STANDARDS_ADHERENCES_FOUND,
  standardsAdherenceFetchError: STANDARDS_ADHERENCE_FETCH_ERROR,
};
</script>

<template>
  <section>
    <gl-alert
      v-if="hasStandardsAdherenceFetchError"
      variant="danger"
      class="gl-mt-3"
      :dismissible="false"
    >
      {{ $options.standardsAdherenceFetchError }}
    </gl-alert>
    <gl-table
      class="gl-mb-6"
      :fields="$options.fields"
      :items="adherences.list"
      :busy="isLoading"
      :empty-text="$options.noStandardsAdherencesFound"
      show-empty
      stacked="lg"
    >
      <template #table-busy>
        <gl-loading-icon size="lg" color="dark" class="gl-my-5" />
      </template>
      <template #cell(status)="{ item: { status } }">
        <span v-if="isFailedStatus(status)" class="gl-text-red-500">
          <gl-icon name="status_failed" /> {{ __('Fail') }}
        </span>
        <span v-else class="gl-text-green-500">
          <gl-icon name="status_success" /> {{ __('Success') }}
        </span>
      </template>

      <template #cell(project)="{ item: { project } }">
        <div>{{ project.name }}</div>
        <div
          v-for="framework in project.complianceFrameworks.nodes"
          :key="framework.id"
          class="gl-label"
          :title="framework.name"
        >
          <gl-badge size="sm" class="gl-mt-3 gl-label-text"> {{ framework.name }}</gl-badge>
        </div>
      </template>

      <template #cell(checks)="{ item: { checkName } }">
        <div class="gl-font-weight-bold">{{ adherenceCheckName(checkName) }}</div>
        <div class="gl-mt-2">{{ adherenceCheckDescription(checkName) }}</div>
      </template>

      <template #cell(standard)="{ item: { standard } }">
        {{ adherenceStandardLabel(standard) }}
      </template>

      <template #cell(lastScanned)="{ item: { updatedAt } }">
        {{ formatDate(updatedAt) }}
      </template>

      <template #cell(fixSuggestions)="{ item }">
        <gl-link @click="toggleDrawer(item)">{{
          s__('ComplianceStandardsAdherence|View details')
        }}</gl-link>
      </template>
    </gl-table>
    <fix-suggestions-sidebar
      :group-path="groupPath"
      :show-drawer="showDrawer"
      :adherence="drawerAdherence"
      @close="closeDrawer"
    />
    <pagination
      v-if="showPagination"
      :is-loading="isLoading"
      :page-info="adherences.pageInfo"
      :per-page="perPage"
      @prev="loadPrevPage"
      @next="loadNextPage"
      @page-size-change="onPageSizeChange"
    />
  </section>
</template>
