<script>
import { GlAlert, GlDisclosureDropdown } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { mapStandardsAdherenceQueryToFilters } from 'ee/compliance_dashboard/utils';
import getProjectsInComplianceStandardsAdherence from 'ee/compliance_dashboard/graphql/compliance_projects_in_standards_adherence.query.graphql';
import { ALLOWED_FILTER_TOKENS } from './constants';
import GroupChecks from './group_checks.vue';
import Filters from './filters.vue';
import AdherencesBaseTable from './base_table.vue';

export default {
  name: 'ComplianceStandardsAdherenceTable',
  components: {
    GlAlert,
    GlDisclosureDropdown,
    Filters,
    AdherencesBaseTable,
    GroupChecks,
  },
  props: {
    groupPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      hasFilterValueError: false,
      hasRawTextError: false,
      projects: {
        list: [],
      },
      filters: {},
      selected: this.$options.i18n.noneText,
    };
  },
  apollo: {
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
    dropdownItems() {
      return [
        {
          text: this.$options.i18n.noneText,
        },
        {
          text: this.$options.i18n.checksText,
        },
      ];
    },
  },
  methods: {
    onFiltersChanged(filters) {
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
    setSelected(selected) {
      this.selected = selected.text;
    },
  },
  i18n: {
    rawFiltersNotSupported: s__(
      'ComplianceStandardsAdherence|Raw text search is not currently supported. Please use the available filters.',
    ),
    invalidFilterValue: s__(
      'ComplianceStandardsAdherence|Raw filter values is not currently supported. Please use available values.',
    ),
    groupByText: s__('ComplianceStandardsAdherence|Group by'),
    filterByText: s__('ComplianceStandardsAdherence|Filter by'),
    noneText: __('None'),
    checksText: __('Checks'),
  },
};
</script>

<template>
  <section>
    <gl-alert v-if="hasFilterValueError" variant="warning" class="gl-mt-3" :dismissible="false">
      {{ $options.i18n.invalidFilterValue }}
    </gl-alert>
    <gl-alert v-if="hasRawTextError" variant="warning" class="gl-mt-3" :dismissible="false">
      {{ $options.i18n.rawFiltersNotSupported }}
    </gl-alert>
    <div class="gl-display-flex gl-md-flex-direction-row row-content-block gl-border-0">
      <div class="gl-display-flex gl-flex-direction-column">
        <label data-testid="dropdown-label" class="gl-line-height-normal">
          {{ $options.i18n.groupByText }}
        </label>
        <gl-disclosure-dropdown
          class="gl-mr-6 gl-lg-mb-0"
          :items="dropdownItems"
          :toggle-text="selected"
          @action="setSelected"
        />
      </div>
      <div class="gl-display-flex gl-flex-direction-column gl-flex-grow-2">
        <label for="target-branch-input" class="gl-line-height-normal">
          {{ $options.i18n.filterByText }}
        </label>
        <filters
          class="gl-mb-2 gl-lg-mb-0"
          :projects="projects.list"
          :group-path="groupPath"
          @submit="onFiltersChanged"
          @clear="clearFilters"
        />
      </div>
    </div>
    <div v-if="selected === 'Checks'">
      <group-checks :group-path="groupPath" :filters="filters" />
    </div>
    <div v-else>
      <adherences-base-table :group-path="groupPath" :filters="filters" />
    </div>
  </section>
</template>
