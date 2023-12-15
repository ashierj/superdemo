<script>
import { GlAlert, GlTable, GlIcon, GlLink, GlBadge, GlLoadingIcon } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { formatDate } from '~/lib/utils/datetime_utility';
import { s__ } from '~/locale';
import { mapStandardsAdherenceQueryToFilters } from 'ee/compliance_dashboard/utils';
import getProjectsInComplianceStandardsAdherence from 'ee/compliance_dashboard/graphql/compliance_projects_in_standards_adherence.query.graphql';
import getProjectComplianceStandardsAdherence from '../../graphql/compliance_standards_adherence.query.graphql';
import Pagination from '../shared/pagination.vue';
import { GRAPHQL_PAGE_SIZE } from '../../constants';
import {
  FAIL_STATUS,
  STANDARDS_ADHERENCE_CHECK_LABELS,
  STANDARDS_ADHERENCE_STANARD_LABELS,
  NO_STANDARDS_ADHERENCES_FOUND,
  STANDARDS_ADHERENCE_FETCH_ERROR,
  ALLOWED_FILTER_TOKENS,
} from './constants';
import FixSuggestionsSidebar from './fix_suggestions_sidebar.vue';
import Filters from './filters.vue';

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
    Filters,
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
      hasFilterValueError: false,
      hasRawTextError: false,
      adherences: {
        list: [],
        pageInfo: {},
      },
      projects: {
        list: [],
      },
      drawerId: null,
      drawerAdherence: {},
      filters: {},
    };
  },
  apollo: {
    adherences: {
      query: getProjectComplianceStandardsAdherence,
      variables() {
        return {
          fullPath: this.groupPath,
          filters: this.filters,
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
    projects: {
      query: getProjectsInComplianceStandardsAdherence,
      variables() {
        return {
          fullPath: this.groupPath,
        };
      },
      update(data) {
        const nodes = data?.group?.projects.nodes || [];
        return {
          list: nodes,
        };
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
    fields() {
      const columnWidth = 'gl-md-max-w-10 gl-white-space-nowrap';

      return [
        {
          key: 'status',
          label: this.$options.i18n.tableHeaders.status,
          sortable: false,
          thClass: columnWidth,
          tdClass: columnWidth,
        },
        {
          key: 'project',
          label: this.$options.i18n.tableHeaders.project,
          sortable: false,
        },
        {
          key: 'check',
          label: this.$options.i18n.tableHeaders.check,
          sortable: false,
          thClass: columnWidth,
          tdClass: columnWidth,
        },
        {
          key: 'standard',
          label: this.$options.i18n.tableHeaders.standard,
          sortable: false,
          thClass: columnWidth,
          tdClass: columnWidth,
        },
        {
          key: 'lastScanned',
          label: this.$options.i18n.tableHeaders.lastScanned,
          sortable: false,
          thClass: columnWidth,
          tdClass: columnWidth,
        },
        {
          key: 'moreInformation',
          label: this.$options.i18n.tableHeaders.moreInformation,
          sortable: false,
          thClass: columnWidth,
          tdClass: columnWidth,
        },
      ];
    },
  },
  methods: {
    adherenceCheckName(check) {
      return STANDARDS_ADHERENCE_CHECK_LABELS[check];
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
    onFiltersChanged(filters) {
      this.hasStandardsAdherenceFetchError = false;
      this.hasFilterValueError = false;
      this.hasRawTextError = false;

      const availableProjectIDs = this.projects.list.map((item) => item.id);

      filters.forEach((filter) => {
        if (
          filter.type === 'standard' &&
          !ALLOWED_FILTER_TOKENS.standards.includes(filter.value.data)
        ) {
          this.hasFilterValueError = true;
        }
        if (filter.type === 'check' && !ALLOWED_FILTER_TOKENS.checks.includes(filter.value.data)) {
          this.hasFilterValueError = true;
        }
        if (filter.type === 'project' && !availableProjectIDs.includes(filter.value.data)) {
          this.hasFilterValueError = true;
        }
        if (!filter.type) {
          this.hasRawTextError = true;
        }
      });

      if (!this.hasFilterValueError) {
        this.filters = mapStandardsAdherenceQueryToFilters(filters);
      }
    },
    clearFilters() {
      this.filters = {};
    },
  },
  noStandardsAdherencesFound: NO_STANDARDS_ADHERENCES_FOUND,
  standardsAdherenceFetchError: STANDARDS_ADHERENCE_FETCH_ERROR,
  i18n: {
    viewDetails: s__('ComplianceStandardsAdherence|View details'),
    viewDetailsFixAvailable: s__('ComplianceStandardsAdherence|View details (fix available)'),
    tableHeaders: {
      status: s__('ComplianceStandardsAdherence|Status'),
      project: s__('ComplianceStandardsAdherence|Project'),
      check: s__('ComplianceStandardsAdherence|Check'),
      standard: s__('ComplianceStandardsAdherence|Standard'),
      lastScanned: s__('ComplianceStandardsAdherence|Last Scanned'),
      moreInformation: s__('ComplianceStandardsAdherence|More Information'),
    },
    rawFiltersNotSupported: s__(
      'ComplianceStandardsAdherence|Raw text search is not currently supported. Please use the available filters.',
    ),
    invalidFilterValue: s__(
      'ComplianceStandardsAdherence|Raw filter values is not currently supported. Please use available values.',
    ),
  },
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
    <gl-alert v-if="hasFilterValueError" variant="warning" class="gl-mt-3" :dismissible="false">
      {{ $options.i18n.invalidFilterValue }}
    </gl-alert>
    <gl-alert v-if="hasRawTextError" variant="warning" class="gl-mt-3" :dismissible="false">
      {{ $options.i18n.rawFiltersNotSupported }}
    </gl-alert>
    <filters
      :projects="projects.list"
      :group-path="groupPath"
      :error="hasStandardsAdherenceFetchError"
      @submit="onFiltersChanged"
      @clear="clearFilters"
    />
    <gl-table
      :fields="fields"
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

      <template #cell(check)="{ item: { checkName } }">
        {{ adherenceCheckName(checkName) }}
      </template>

      <template #cell(standard)="{ item: { standard } }">
        {{ adherenceStandardLabel(standard) }}
      </template>

      <template #cell(lastScanned)="{ item: { updatedAt } }">
        {{ formatDate(updatedAt) }}
      </template>

      <template #cell(moreInformation)="{ item }">
        <gl-link @click="toggleDrawer(item)">
          <template v-if="isFailedStatus(item.status)">{{
            $options.i18n.viewDetailsFixAvailable
          }}</template>
          <template v-else>{{ $options.i18n.viewDetails }}</template>
        </gl-link>
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
