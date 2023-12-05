<script>
import { GlTab, GlTabs, GlTooltipDirective } from '@gitlab/ui';

import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

import Tracking from '~/tracking';
import {
  ROUTE_STANDARDS_ADHERENCE,
  ROUTE_FRAMEWORKS,
  ROUTE_PROJECTS,
  ROUTE_VIOLATIONS,
} from '../constants';
import ReportHeader from './shared/report_header.vue';
import Export from './shared/export_disclosure_dropdown.vue';

export default {
  name: 'ComplianceReportsApp',
  components: {
    GlTabs,
    GlTab,
    ReportHeader,
    Export,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin()],
  inject: ['complianceFrameworkReportUiEnabled'],
  props: {
    mergeCommitsCsvExportPath: {
      type: String,
      required: false,
      default: '',
    },
    frameworksCsvExportPath: {
      type: String,
      required: false,
      default: '',
    },
    violationsCsvExportPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    tabIndex() {
      const currentTabs = [
        ROUTE_STANDARDS_ADHERENCE,
        ROUTE_VIOLATIONS,
        ROUTE_FRAMEWORKS,
        ROUTE_PROJECTS,
      ];

      return currentTabs.indexOf(this.$route.name);
    },
    standardsAdherenceTabLinkAttributes() {
      return { 'data-testid': 'standards-adherence-tab' };
    },
    violationsTabLinkAttributes() {
      return { 'data-testid': 'violations-tab' };
    },
    frameworksTabLinkAttributes() {
      return { 'data-testid': 'frameworks-tab' };
    },
    projectsTabLinkAttributes() {
      return { 'data-testid': 'projects-tab' };
    },
  },
  methods: {
    goTo(name) {
      if (this.$route.name !== name) {
        this.$router.push({ name });
        this.track('click_report_tab', { label: name });
      }
    },
  },
  ROUTE_STANDARDS: ROUTE_STANDARDS_ADHERENCE,
  ROUTE_VIOLATIONS,
  ROUTE_FRAMEWORKS,
  ROUTE_PROJECTS,
  i18n: {
    frameworksTab: s__('Compliance Center|Frameworks'),
    projectsTab: __('Projects'),
    heading: __('Compliance center'),
    standardsAdherenceTab: s__('Compliance Center|Standards Adherence'),
    subheading: __(
      'Report and manage standards adherence, violations, and compliance frameworks for the group.',
    ),
    violationsTab: s__('Compliance Center|Violations'),
  },
  documentationPath: helpPagePath('user/compliance/compliance_center/index.md'),
};
</script>
<template>
  <div>
    <report-header
      :heading="$options.i18n.heading"
      :subheading="$options.i18n.subheading"
      :documentation-path="$options.documentationPath"
    >
      <template #actions>
        <export
          class="gl-float-right"
          :frameworks-csv-export-path="frameworksCsvExportPath"
          :merge-commits-csv-export-path="mergeCommitsCsvExportPath"
          :violations-csv-export-path="violationsCsvExportPath"
        />
      </template>
    </report-header>

    <gl-tabs :value="tabIndex" content-class="gl-p-0" lazy>
      <gl-tab
        :title="$options.i18n.standardsAdherenceTab"
        :title-link-attributes="standardsAdherenceTabLinkAttributes"
        data-testid="standards-adherence-tab-content"
        @click="goTo($options.ROUTE_STANDARDS)"
      />
      <gl-tab
        :title="$options.i18n.violationsTab"
        :title-link-attributes="violationsTabLinkAttributes"
        data-testid="violations-tab-content"
        @click="goTo($options.ROUTE_VIOLATIONS)"
      />
      <gl-tab
        v-if="complianceFrameworkReportUiEnabled"
        :title="$options.i18n.frameworksTab"
        :title-link-attributes="frameworksTabLinkAttributes"
        data-testid="frameworks-tab-content"
        @click="goTo($options.ROUTE_FRAMEWORKS)"
      />
      <gl-tab
        :title="$options.i18n.projectsTab"
        :title-link-attributes="projectsTabLinkAttributes"
        data-testid="projects-tab-content"
        @click="goTo($options.ROUTE_PROJECTS)"
      />
    </gl-tabs>
    <router-view />
  </div>
</template>
